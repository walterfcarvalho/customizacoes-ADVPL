#include "Protheus.ch"
#include "Rwmake.ch"
#include "Topconn.ch"
#include "fileio.ch"

/*	carga automatica da CF
	Ao compilar, compilar junto dtHrToN.prw, hash.prw, cf_messages.prw
*/
user function cfCargaInc(cLoja, lAtuAll, oProcess, lEnd)
	Local i			:= 1
	Local cRes		:= ""
	Local cmd		:= ""
	Local aAtualiza := {}
	Local aCampos	:= {}
	Private oHc := Hash():new("\_cargaCF.ini", .F.)
	Private nHandR
	Private nHandL
	Private cArqLog	:= "\_cargaCF.Log"

	FErase(cArqLog)

	if !Vazio(GetGlbValue("cfCargaInc"))
		cRes := "Há outro procedimento de carga sendo feito no momento..."
		conOut("cfCargaInc() " + cRes)
		return cRes
	else
		conOut("cfCargaInc() Setando estado da carga para ativo." + cRes)
		PutGlbValue ("cfCargaInc", "1" )
	endIf

	If Select("SX2") == 0    // Conecto ao ambiente caso a execução seja feita a partir de um JOB.
		RPCSetType(3)
		RPCSetEnv("01",cLoja,Nil,Nil,"LOJA")
	Endif

	conout("cfCargaInc() Filial:" + cLoja)


	// criar parametros se nao existirem
	criaParam("CF_UCD", "C", "ULTIMA CARGA - DATA", dtos(date()))
	criaParam("CF_UCH", "C", "ULTIMA CARGA - HORA", "00:00:00")
	criaParam("CF_UCINTV", "C", "ULTIMA CARGA - INTERVALO EXECUCAO EM SEGUNDOS", "600")

//	nHandL := TCGetConn()

	nHandR 	:= openConn()   // pega a conexao
	If nHandR < 0
		cmd := "cfCargaInc() Nao consegui efetuar a conexao."
		conOut(cmd)
		conout("cfCargaInc() - Fim")
		conOut("----------------------------------------------------")
		PutGlbValue ("cfCargaInc",  "")
		return cmd
	else
		conOut := "cfCargaInc() Conexao com a retaguarda ok."
	endif

	// verifica se está na hora de fazer a carga
	aAtualiza := FIsShowTime(lAtuAll)

	if (aAtualiza[3] <> "Ok") .and. ( Vazio(lAtuAll) )
		PutGlbValue ("cfCargaInc",  "")
		conout("cfCargaInc() - Fim")
		conOut("----------------------------------------------------")
		return aAtualiza[3]
		conOut("----------------------------------------------------")
	endIf


	// pega a lista de chaves no hash
	aCampos :=  oHc:getHashs()
	if !vazio(oProcess)
		oProcess:SetRegua1(len(aCampos))
	endIf

	conOut("Vou atualizar " + cvalToChar(Len(aCampos)) + " tabelas.")
	conOut("cfCargaInc() Registros a partir de: " + getmv("CF_UCD") + " Hora:" + getmv("CF_UCH") )
	for i:=1 to len(aCampos)
		 if lEnd
		 	return cres
		 endIf

		if  AT('carga', aCampos[i]) > 0
			cNomeTb	:=  oHc:gpc(aCampos[i], 2 )
			cCodFil	:=  iif( oHc:gpc(aCampos[i], 1) = '1' , cLoja, XFilial(cNomeTb))
			cNmTbBd :=  oHc:gpc(aCampos[i], 3 )
			cPrfCps	:=  oHc:gpc(aCampos[i], 4 )
			nIdx	:=  oHc:gpL(aCampos[i], 5 )
			aCposIdx:=  oHc:getArrayN(6, aCampos[i])
			cWhere	:=  oHc:gpc(aCampos[i], 7 )
			aLstCp  :=  oHc:getArray (8, aCampos[i])

			if !vazio(oProcess)
				oProcess:IncRegua1("Tabela " + cNomeTb + " - " + Posicione("SX2", 1, cNomeTb, "X2_NOME")   )
			endIf

			cRes += cargaTbl(cNmTbBd, cPrfCps,   aLstCp, cNomeTb, nIdx, aCposIdx, cWhere, cCodFil, lAtuAll, @oProcess) 				+ CRLF
		endIf
	next

	// fecha a conexao
	TCUnlink()

	// gravar os novos dados dos parametros
	If vazio(lAtuAll)
		PutMv("CF_UCD", aAtualiza[1] )    // Após o parâmetro a criação do parâmetro seto o conteúdo.
		PutMv("CF_UCH", aAtualiza[2] )    // Após o parâmetro a criação do parâmetro seto o conteúdo.
	endIf

	conout(cRes)
	conout("cfCargaInc() - Fim")
	conOut("----------------------------------------------------")
	PutGlbValue ("cfCargaInc",  "")
return cRes

static function cargaTbl(cNmTb, cPrefixo, aCampoTb, _cAlias, nIdx, aCpPesq, cAndExtra, cLjPesq, lAtuAll, oProcess)
	Local lLock
	Local cRes	:= ""
	Local nIns	:= 0
	Local nUpd	:= 0
	Local nDel	:= 0
	Local cCp	:= ""
	Local cData	:= iif(vazio(lAtuAll), GetMV("CF_UCD"), "20170101")
	Local cHora := iif(vazio(lAtuAll), GetMV("CF_UCH"), "00:00:00")
	Local cmd 	:= ""

	Local adados:= {}
	Local aLin	:= {}
	Local cStrPesq := ""

	ConOut("cfCargaInc() cargaTbl() Tabela: " + _cAlias )

	if !vazio(oProcess)
		oProcess:SetRegua2(3)
		oProcess:IncRegua2("Obtendo registros no servidor...")
	endIf


	// Montagem da String de consulta ao banco
	aadd(aCampoTb, " D_E_L_E_T_ as APAGAR " )
	for i:= 1 to len(aCampoTb)-1
		cCp += aCampoTb[i] + ", "
		 if i % 10 = 0
		 	cCp += char(13) + char(10)
		 endIf
	next
	cCp += aCampoTb[len(aCampoTb)]

	cmd :=	CRLF + " Select " + cCp 																																					+ CRLF + ;
	" from " + cNmTb + " with(nolock) where R_E_C_N_O_ IN ( "  																													+ CRLF + ;
	"	select ZZ0_NREG from ZZ0010 with(nolock) where ZZ0_FILIAL= '" + cLjPesq + "' and ZZ0_TABELA= '" + _cAlias + "' and ZZ0_DATA= " + cData + " and ZZ0_HORA> '"+ cHora + "' "	+ CRLF + ;
	"   UNION ALL"																														    										+ CRLF + ;
	"   select ZZ0_NREG from ZZ0010 with(nolock) where ZZ0_FILIAL= '" + cLjPesq + "' and ZZ0_TABELA= '" + _cAlias + "' and ZZ0_DATA> " + cData 										+ CRLF + ;
	" ) "																																											+ CRLF

	fGrvLog(cmd)

	conOut("cfCargaInc() cargaTbl() Consulta Remota, tabela " + _cAlias)
	TcSetConn(nHandR)
	dbUseArea(.t.,"TOPCONN",tcGenQry(,,cmd),"ZCT",.t.,.t.)

	ConOut("cfCargaInc() cargaTbl() Copiando registros para a maquina local. " )

	if !vazio(oProcess)
		oProcess:SetRegua2(3)
		oProcess:IncRegua2("Copiando para a maquina local...")
	endIf

	While !ZCT->(Eof())
		aLin := {}
		for i:= 1 to len(aCampoTb) -1
			aadd(aLin, ZCT-> &(aCampoTb[i]))
		next

		aadd(aLin, ZCT->APAGAR)

		aadd(adados, aLin )
		ZCT->(DbSkip())
	endDo
	ZCT->(DbCloseArea())

	ConOut("cfCargaInc() cargaTbl() Atualizando " + _cAlias+ " local " + cValTochar(Len(adados)) + " registros." )

//	TcSetConn(nHandL)
	DbSelectArea(_cAlias)
	DbSetOrder(nIdx)

	for i:=1 to Len(adados)

		if !vazio(oProcess)
			oProcess:SetRegua2(Len(adados))
			oProcess:IncRegua2("Atualizando " + cValToChar(Len(adados)) + " registros...")
		endIf

		cStrPesq := ""
		for j:=1 to Len(aCpPesq)
			cStrPesq += aDados[i, aCpPesq[j] ]
		next

		if DbSeek(cStrPesq)
			lLock := recLock(_cAlias, .F.)
		else
			lLock := recLock(_cAlias, .T.)
			if aDados[i, len(aLin)] <> '*'
				nIns++
			endIf
		endIf

		if !lLock
			conOut("Não consegui efetuar o lock na tabela: " + _cAlias + " Indice: " + nIdx + " Chave: " + cStrPesq  )
		endIf

		// se for delecao
		if  aDados[i, len(aLin)] = '*'
			(_cAlias)->(DbDelete())
			nDel++
		else // Se insercao/update, atualize os campos
			for x:=1 to len(aCampoTb)-1
				if type((_cAlias)->(aCampoTb[x])) == "D"
					(_cAlias)-> &(aCampoTb[x]) := ctod(aDados[i, x])
				else
					(_cAlias)-> &(aCampoTb[x]) := aDados[i, x]
				endIf
			next
			nUpd++
		endIf
		MsUnlock()
	Next

	&(_cAlias)->(DbcloseArea())

	cRes := _cAlias + ", inseridos: " + cValToChar(nIns) + ", atualizados: " + cValToChar(nUpd) + ", deletados: " + cValToChar(nDel)
	ConOut("cfCargaInc() cargaTbl() " + cRes)
	ConOut("")
return cRes

Static Function openConn()
	Local cIp 		:= GetMV("MV_YENDEBD")
	Local cPorta	:= GetMV("MV_YPORTBD")
	ConOut("cfCargaInc() openConn() Ip:" + cIp +" Porta:" + cValToChar(cPorta) )
Return( TCLink( "MSSQL/TOTVSPROD", cIp, cPorta ) )

/*	retorna array
1 - data tipo data
2 - hora tipo String    */
Static function FgetDataHora()
	Local aDataHora := {}
	Local cAux		:= {}

	TcSetConn(nHandR)

	cmd := "select CONVERT(VARCHAR(8),GETDATE(),112) as CDATA, CONVERT(VARCHAR(8),GETDATE(),108) AS CHORA
	dbUseArea(.t.,"TOPCONN",tcGenQry(,,cmd),"ZCT",.t.,.t.)
	aadd(aDataHora, ZCT->CDATA )
	aadd(aDataHora, ZCT->CHORA )
	ZCT->(DbCloseArea())
return aDataHora

Static Function criaParam( cParam, cType, cDescri, xCont )
	dbSelectArea("SX6")
	SX6->(dbSetOrder(1))
	If !( SX6->(dbSeek( xFilial("SX6") + cParam )) )  // Se não encontrar esse parâmetro na tabela SX6. O sistema o cria.
		recLock("SX6",.t.)
		Replace SX6->X6_FIL     with xFilial("SX6")
		Replace SX6->X6_VAR     with cParam
		Replace SX6->X6_TIPO    with cType
		Replace SX6->X6_DESCRIC with cDescri
		Replace SX6->X6_PROPRI  with "U"
		msUnlock()
		PutMv( cParam, xCont)    // Após o parâmetro a criação do parâmetro seto o conteúdo.
	Endif
return


Static Function FIsShowTime(lAtuAll)
	Local aDtHrR	:= {}
	Local cDtL
	Local cHrL
	Local nInterv

	cDtL 			:= GetMV("CF_UCD")
	cHrL 			:= GetMV("CF_UCH")
	nInterv			:= val(GetMV("CF_UCINTV"))

	// pegue a data e hora do servidor
	aDtHrR	:= FgetDataHora()

	// aDtHrR[1] + " " + aDtHrR[2] + "   " + cDtL + "  " + ChRl
	// comparar a data do parametro com a do servidor
// (u_dtHrToN("20170531", "23:59:00") - u_dtHrToN("20170601", "01:00:00"))
	if vazio(lAtuAll)
		if (u_dtHrToN(aDtHrR[1], aDtHrR[2]) - u_dtHrToN(cDtL, cHrL) ) < nInterv
			aadd( aDtHrR, "- Não esta na hora de atualizar, faltam "   + cValToChar( nInterv - (u_dtHrToN(aDtHrR[1], aDtHrR[2]) - u_dtHrToN(cDtL, cHrL))) + " segundos. "  )
			PutGlbValue ("cfCargaInc",  "Setando estado da carga para inativo.")
		else
			aadd( aDtHrR, "Ok")
		endIf
	else
		aadd( aDtHrR, "Ok")
	endIf
	conOut("cfCargaInc() FIsShowTime() " + aDtHrR[3])
return aDtHrR


static function fGrvLog(cLinha)
	Local nHandle := 0
	if !File(cArqLog)
		nHandle := fCreate(cArqLog)
		Fclose(nHandle)
	EndIf

	nHandle := fOpen(cArqLog, FO_READWRITE + FO_SHARED )

	cLinha +=  + CHR(13) + CHR(10)

	If nHandle == -1
		conOut('Erro de abertura no arquivo de log :FERROR ' + str(fError(),4))
		return .F.
	Else
		FSeek(nHandle, 0, FS_END)         // Posiciona no fim do arquivo
		FWrite(nHandle, clinha, LEN(cLinha)) // Insere texto no arquivo
		fclose(nHandle)                   // Fecha arquivo
	Endif
return .T.
