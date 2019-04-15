#include "fileio.ch"
#include 'parmtype.ch'
#include "Protheus.ch"
#include "Rwmake.ch"
#include 'TOPCONN.CH'

#define CRLF char(13) + char(10)
#define cROTINA  "cargaLoja() "

/*	carga automatica dE lOJA
Ao compilar, compilar junto dtHrToN.prw, DG_messages.prw
*/
user function cfCargaInc(cLoja, lValTempo, oProcess, lEnd)
	Local oXml
	Local cReplace 	:= "" 
	Local cErros	:= ""
	Local cAvisos   := ""
	Local i			:= 1
	Local cRes		:= ""
	Local cmd		:= ""
	Local aAtualiza := {}
	Local aCampos	:= {}
	Private nHandR
	Private lCheck	:= .F.	
	Private cArqLog	:= "\_cargaLoja.Log"


//    atualizaArquivos()


	FErase(cArqLog)

	if !Vazio(GetGlbValue(cROTINA))
		cRes := "Há outro procedimento de carga sendo feito no momento..."
		conOut(cROTINA + cRes)
		return cRes
	else
		conOut(cROTINA + "Setando estado da carga para ativo." + cRes)
		PutGlbValue (cROTINA, "1" )
	endIf

	If Select("SX2") == 0    // Conecto ao ambiente caso a execução seja feita a partir de um JOB.
		RPCSetType(3)
		RPCSetEnv("01",cLoja,Nil,Nil,"LOJA")
	Endif




	oXml := XmlParser(MemoRead("\_cargaLoja.xml"), cReplace, @cErros, @cAvisos)
	if (cErros <> "") .or. (cAvisos <> "")
		cRes := "Houve problema ao carregar o Xml do arquivo " + cArqLog + CRLF + "Erros : " + cErros + CRLF + "Avisos: " + cAvisos
		conOut(cROTINA + cRes)
		conOut("")
		return cRes
	endIf

	conout(cROTINA + "Filial: " + cLoja)

	// criar parametros se nao existirem

	criaParam("CT_YNMODB"	, "C", "ULTIMA Alias do Odbc"							, "Producao22") 	// alias ODBC do servidor
	criaParam("CT_YENDEBD"	, "C", "ULTIMA Ip DbAcces Adm"							, "172.32.0.16") 	// ip digaspi
	criaParam("CT_YPORTBD"	, "N", "ULTIMA porta Dbaccess Adm"						, "7890")		// porta do
	criaParam("CT_UCD"		, "C", "ULTIMA CARGA - DATA"							, dtos(date()))
	criaParam("CT_UCH"		, "C", "ULTIMA CARGA - HORA"							, "00:00:00")
	criaParam("CT_UCINTV"	, "C", "ULTIMA CARGA - INTERVALO SEGUNDOS EXEC "		, "600")
	criaParam("CT_UATUHR"	, "C", "ULTIMA CARGA - Atu por data/hora(DH) ou data(D)", "DH" )
	

	nHandR 	:= openConn()   // pega a conexao
	If nHandR < 0
		cRes :=  "Houve erro ao tentar conectar no server remoto."
		conout(cROTINA + "Filial: " + cRes)
		return cRes
	endif

	// verifica se está na hora de fazer a carga
	aAtualiza := FIsShowTime(lValTempo)  

	if (aAtualiza[3] <> "Ok") .and. ( Vazio(lValTempo) )
		PutGlbValue (cROTINA, "")
		conout(cROTINA + " - Fim")
		conOut("----------------------------------------------------")
		return aAtualiza[3]
		conOut("----------------------------------------------------")
	endIf
	TCUnlink(nHandR, .T.)
	
	// pega a lista de tabelas no XML
	//	aCampos :=  oHc:getHashs()
	for i:=1 to len(oxml:_xml:_carga)
		aadd(aCampos, Limpa(oxml:_xml:_carga[i]:_tabela:text)  )
	Next

	if !vazio(oProcess)
		oProcess:SetRegua1(len(aCampos))
	endIf

	conOut(cROTINA + "Vou atualizar " + cvalToChar(Len(aCampos)) + " tabelas: " + ArrToKStr(aCampos))
	conOut(cROTINA + "Registros a partir de: " + getmv("CT_UCD") + " Hora:" + getmv("CT_UCH") )
	for i:=1 to len(aCampos)
		if lEnd
			return cres
		endIf
		begin sequence
			nHandR 	:= openConn()   // pega a conexao
		
			cNomeTb	:=  aCampos[i]
			cCodFil	:=  iif( Limpa(oxml:_xml:_carga[i]:_ehporfil:text) = '1' , cLoja, XFilial(cNomeTb)     )    // iif( oHc:gpc(aCampos[i], 1) = '1' , cLoja, XFilial(cNomeTb))
			cNmTbBd :=  Limpa(oxml:_xml:_carga[i]:_tbbanco:text)												//oHc:gpc(aCampos[i], 3 )
			cPrfCps	:=  Limpa(oxml:_xml:_carga[i]:_preftb:text)													//oHc:gpc(aCampos[i], 4 )
			nIdx	:=  Val(Limpa(oxml:_xml:_carga[i]:_idxtb:text))												//	oHc:gpL(aCampos[i], 5 )
			aCposIdx:=  StrTokArr( Limpa(oxml:_xml:_carga[i]:_camposIdx:text), "," )							//oHc:getArrayN(6, aCampos[i])
			cWhere	:=  Limpa(oxml:_xml:_carga[i]:_where:text)													//oHc:gpc(aCampos[i], 7 )
			aLstCp  :=  getLstCampos(Limpa(oxml:_xml:_carga[i]:_tabela:text), Limpa(oxml:_xml:_carga[i]:_campos:text))   								//StrTokArr( Limpa(oxml:_xml:_carga[i]:_campos:text), "," )								//oHc:getArray (8, aCampos[i])

			if !vazio(oProcess)
				oProcess:IncRegua1("Tabela " + cNomeTb + " - " + Posicione("SX2", 1, cNomeTb, "X2_NOME")   )
			endIf
	
			cRes += cargaTbl(cNmTbBd, cPrfCps, aLstCp, cNomeTb,  nIdx, aCposIdx, cWhere, cCodFil, @oProcess) 				+ CRLF

			TCUnlink(nHandR, .T.)
		recover
			conOut(cROTINA + "Ocorreu um problema na seguinte carga: " + cNomeTb )
		end Sequence
	next


	// gravar os novos dados dos parametros
	PutMv("CT_UCD", aAtualiza[1] )    // Após o parâmetro a criação do parâmetro seto o conteúdo.
	PutMv("CT_UCH", aAtualiza[2] )    // Após o parâmetro a criação do parâmetro seto o conteúdo.

	conout(cRes)
	conout(cROTINA + "- Fim")
	conOut("----------------------------------------------------")
	PutGlbValue (cROTINA,  "")
return cRes

static function cargaTbl(cNmTb, cPrefixo, aCampoTb, _cAlias, nIdx, aCpPesq, cAndExtra, cLjPesq, oProcess)
	Local lLock
	Local i,j,x
	Local cAux	:= ""
	Local cRes	:= ""
	Local nIns	:= 0
	Local nUpd	:= 0
	Local nDel	:= 0
	Local cCp	:= ""
	Local cData	:= GetMV("CT_UCD")
	Local cHora := GetMV("CT_UCH")
	Local cmd 	:= ""

	Local adados:= {}
	Local aLin	:= {}
	Local cStrPesq := ""

	fGrvLog( CRLF + CRLF + cROTINA + "cargaTbl() Tabela: " + _cAlias  )
	ConOut(cROTINA + "cargaTbl() Tabela: " + _cAlias )

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

	cmd :=	CRLF + " Select " + cCp 																																										+ CRLF + ;
	" from " + cNmTb + " with(nolock) where R_E_C_N_O_ IN ( "  																																				+ CRLF

	if getMV("CT_UATUHR") == "DH"
		cmd += ;
		"	select R_E_C_N_O_ from " + cNmTb + " with(nolock) where " + cPrefixo + "_FILIAL= '" + cLjPesq + "' and " + cPrefixo + "_MSEXP= '" + cData + "' and "  + cPrefixo + "_HREXP> '"+ cHora + "' "	+ CRLF + ;
		"   UNION ALL "																														    															+ CRLF
	endif

	cmd += ;
	"   select R_E_C_N_O_ from " + cNmTb + " with(nolock) where " + cPrefixo + "_FILIAL= '" + cLjPesq + "' and " + cPrefixo + "_MSEXP> '" + cData 										+ "' " 				+ CRLF + ;
	" ) "																																																	+ CRLF

	fGrvLog(cmd)

	conOut(cROTINA + "cargaTbl() Consulta Remota, tabela " + _cAlias)
	TcSetConn(nHandR)
	dbUseArea(.t.,"TOPCONN",tcGenQry(,,cmd),"ZCT",.t.,.t.)

	ConOut(cROTINA + "cargaTbl() Copiando registros para a maquina local. " )

	if !vazio(oProcess)
//		oProcess:SetRegua2(3)
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

	// desconecta do remoto
	TcUnlink( nHandR )

	ConOut(cROTINA + "cargaTbl() Atualizando " + _cAlias+ " local " + cValTochar(Len(adados)) + " registros." )

	DbSelectArea(_cAlias)
	DbSetOrder(nIdx)

	if !vazio(oProcess)
		oProcess:SetRegua2(Len(adados))		
	endIf

	for i:=1 to Len(adados)

		if !vazio(oProcess)
			oProcess:IncRegua2("Atualizando registro " + cvaltochar(i) + " de " +  cValToChar(Len(adados)) )
		endIf

		cStrPesq := ""
		for j:=1 to Len(aCpPesq)
			cStrPesq += aDados[i, Val(aCpPesq[j]) ]
		next

		lSeek :=  (_cAlias)->(DbSeek(cStrPesq))

		fGrvLog( " chave:" +  cStrPesq )


		if  lSeek = .T.
			fGrvLog( "Seek: .T., atualizar" )

			lLock := recLock(_cAlias, .F.)
			nUpd++			
		else
			fGrvLog( "Seek: .F., inserir " )

			lLock := recLock(_cAlias, .T.)
			if aDados[i, len(aLin)] <> '*'
				nIns++
			else			
				nDel++	
			endIf
		endIf

		if !lLock
			fGrvLog( "Nao consegui efetuar o lock do registro " )
			ConOut(cROTINA + "Não consegui efetuar o lock na tabela: " + _cAlias + " Indice: " + nIdx + " Chave:" + cStrPesq  )
			Loop
		endIf

		// se for delecao
		if  aDados[i, len(aLin)] = '*'
			fGrvLog( "Registro para delecao" )
			(_cAlias)->(DbDelete())
		else // Se insercao/update, atualize os campos
			for x:=1 to len(aCampoTb)-1
				cAux :=  Limpa(aCampoTb[x])

				if type((_cAlias)->(cAux)) == "D"
					replace  (_cAlias)-> &(cAux)  with ctod(aDados[i, x])
				else
					replace  (_cAlias)-> &(cAux)  with (aDados[i, x])
				endIf
			next
		endIf
		MsUnlock()
		
		fGrvLog( CRLF + CRLF )

	Next

	&(_cAlias)->(DbcloseArea())

	cRes := _cAlias + ", inseridos: " + cValToChar(nIns) + ", atualizados: " + cValToChar(nUpd) + ", deletados: " + cValToChar(nDel) + " Total: " + cValToChar(nIns + nUpd + nDel)
	ConOut(cROTINA + "cargaTbl() " + cRes)
	ConOut("")
return cRes

Static Function openConn()
	Local nHandle	:= -1
	Local cODBC		:= "MSSQL/" + GetMV("CT_YNMODB")
	Local cIp 		:= GetMV("CT_YENDEBD")
	Local cPorta	:= GetMV("CT_YPORTBD")
	ConOut(cROTINA + "o_penConn() Ip:" + cIp +" Porta:" + cValToChar(cPorta) )

	nHandle := TCLink( cODBC, cIp, cPorta)

	If nHandle < 0
		cmd := cROTINA + "o_penConn() Nao consegui efetuar a conexao."
		conOut(cmd)
		conOut("----------------------------------------------------")
		PutGlbValue (cROTINA,  "")
	else
		conOut(cROTINA + "o_penConn() Conexao com a retaguarda ok.")
	endif

Return( nHandle  )

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

Static Function FIsShowTime(lValTempo)
	Local aDtHrR	:= {}
	Local cDtL
	Local cHrL
	Local nInterv

	cDtL 			:= GetMV("CT_UCD")
	cHrL 			:= GetMV("CT_UCH")
	nInterv			:= val(GetMV("CT_UCINTV"))

	// pegue a data e hora do servidor
	aDtHrR	:= FgetDataHora()

	if vazio(lValTempo)
		if (u_dtHrToN(aDtHrR[1], aDtHrR[2]) - u_dtHrToN(cDtL, cHrL) ) < nInterv
			aadd( aDtHrR, "- Não esta na hora de atualizar, faltam "   + cValToChar( round(nInterv - (u_dtHrToN(aDtHrR[1], aDtHrR[2]) - u_dtHrToN(cDtL, cHrL)),2)) + " segundos. "  )
			PutGlbValue(cROTINA,  "Setando estado da carga para inativo.")
		else
			aadd( aDtHrR, "Ok")
		endIf
	else
		aadd( aDtHrR, "Ok")
	endIf
	conOut(cROTINA + "FIsShowTime() " + aDtHrR[3])
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
		conOut(cROTINA + "Erro de abertura no arquivo de log :FERROR " + str(fError(),4))
		return .F.
	Else
		FSeek(nHandle, 0, FS_END)         		// Posiciona no fim do arquivo
		FWrite(nHandle, clinha, LEN(cLinha)) 	// Insere texto no arquivo
		fclose(nHandle)                   		// Fecha arquivo
	Endif
return .T.


static function Limpa(cStr)
	Local aLstChar := {9,10}
	Local i
	Local cRes	:= ""

	cStr := Alltrim(cStr)

	for i:= 1  to len(cStr)
		if aScan(aLstChar,  ASC(SUBSTR(cStr, i, 1)) ) = 0 
			cRes += SUBSTR(cStr, i, 1)
		endif
	Next
return cRes

static function getLstCampos(cTabela, cCampos)
	Local i
	Local aCampos := StrTokArr( cCampos, "," )

	if  aCampos[1] = "*"
		aCampos := {}

		DbSelectArea("SX3")
		DbSetOrder(1)
		DbSeek(cTabela)

		while SX3->X3_ARQUIVO = cTabela
			aadd(aCampos, Alltrim(SX3->X3_CAMPO)) 
			SX3->(DbSkip())
		endDo
	else
		for i:=1 to len(aCampos)
			aCampos[i] := Alltrim(aCampos[i])
		Next
	endif
return aCampos

user function getX6(cParam)
return getmv(cParam)


static function atualizaArquivos()
  Local aFiles := {} // O array receberá os nomes dos arquivos e do diretório
  Local aSizes := {} // O array receberá os tamanhos dos arquivos e do diretorio
  Local nX
  
  ADir("\*.*", aFiles, aSizes)
  // Exibe dados dos arquivos
  nCount := Len( aFiles )
  For nX := 1 to nCount
    ConOut( 'Arquivo: ' + aFiles[nX] + ' - Size: ' + AllTrim(Str(aSizes[nX])) )
  Next nX
  
Return

