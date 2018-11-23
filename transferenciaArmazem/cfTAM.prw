#include 'protheus.ch'
#include 'parmtype.ch'
#include "TOPCONN.CH"
#include "TOTVS.CH"

/*/{Protheus.doc} cfTAM
Fonte para transferir mercadoria entre os armazens da loja
a fila é  alimentada pela venda assitida.

@author valter
@since 08/05/2017
@version 1
@type function
/*/
user function cfTAM()
	Local cmd
	Local oSay1
	Local aCpoBro 		:= getMasks()
	Local aCores		:= {}
	private _stru 		:= getStruct()
	Private cMark		:= GetMark()
	Private oMark
	Private oCheck
	Private lCheck		:= .F.
	Private lInverte 	:= .F.
	private lUsrAdm		:= RetCodUsr() $ getMV("CF_TAMADM")
	Private LOCORIG		:= GetMv("CF_TAMORIG")
	Private LOCDEST		:= GetMv("CF_TAMDEST")
	Private aItBrw		:= {}
	Private lUsaCol

	lUsaCol		:=  .T.
	if lUsrAdm
		lUsaCol := u_mquestion("Usuário com permissão alta, deseja usar o Coletor ?") = .T.
	endIf

	if GetMv("CF_CODARML") = ""
		u_mErro(" Essa funcionalidade não funciona nessa filial - CF_CODARML" )
		return
	endIf

	if (lUsaCol = .T.)
		cmd := GetMV("cf_AppCol") // pega o caminho do coletor

		if File(cmd)
			ShellExecute( "Open", cmd, "", "C:\Smartclient", 0 )
		else
			u_mErro("Não achei a aplicacao do coletor, se essa estacao for trabalhar com coletor, tem que instalar ela primeiro." + CRLF + "Caminho:" + cmd)
		endif
	endIf

	cArq := Criatrab(_stru, .T.)
	DBUSEAREA(.t.,,cArq, "TBOS")

	DEFINE MSDIALOG oDlg TITLE "Fila de produtos para abastecer loja - CFTAM" From 9,0 To 570, 1000 PIXEL

	oMark := MsSelect():New("TBOS","OK","",aCpoBro,@lInverte,@cMark,{30,001,270,500},,,,,aCores)
	oMark:bMark := {| | Disp()}

	@ 003, 001 BUTTON oBtLoad PROMPT "Listar(F5)"    SIZE 042, 022 OF oDlg ACTION FGetAtu() PIXEL

	@ 003, 080 BUTTON oBtLoad PROMPT "Adicionar(F7)" SIZE 042, 022 OF oDlg ACTION u_cfReqLjAmr() PIXEL

	@ 003, 280 BUTTON oBtgera PROMPT "Imprime(F9)"  SIZE 042, 022 OF oDlg ACTION FImpFila(aItBrw) PIXEL

	@ 003, 350 BUTTON oBtgera PROMPT "Remover(F10)"  SIZE 042, 022 OF oDlg ACTION FchItFila() PIXEL

	@ 003, 430 BUTTON oBtgera PROMPT "Gerar(F12)"    SIZE 042, 022 OF oDlg ACTION  FGetTransf() PIXEL

	if lUsrAdm = .T.
		@ 003, 130 BUTTON oBtLoad PROMPT "Define Orig/Dest"     SIZE 055, 015 OF oDlg ACTION FDeforigDest() PIXEL
		@ 003, 190 BUTTON oBtLoad PROMPT "Importar de contagem" SIZE 055, 015 OF oDlg ACTION FWMsgRun(, {|| lerArq() },"", "Aguarde..." ) PIXEL
	endIf

	@ 272, 003 SAY oSay1 PROMPT "Duplo clique na solicitação, ou ENTER para marca-la. " SIZE 400, 007 OF oDlg COLORS 0, 16777215 PIXEL

	oCheck := TCheckBox():Create( oDlg,{||},272,300,'Marcar/Desmarcar Todos.',100,210,,{|| fMarcaDesmarca() },,,,,,.T.,,,)

	SET KEY VK_F5 TO
	SETKEY(VK_F5,{|| FGetAtu() })

	SET KEY VK_F7 TO
	SETKEY(VK_F7,{|| u_cfReqLjAmr(),  FGetAtu() })

	SET KEY VK_F10 TO
	SETKEY(VK_F10,{|| FchItFila() })

	SET KEY VK_F12 TO
	SETKEY(VK_F12,{|| FGetTransf() })

	SET KEY VK_F9 TO
	SETKEY(VK_F12,{|| FImpFila(aItBrw) })

	//Exibe a Dialog
	ACTIVATE MSDIALOG oDlg CENTERED

	//Fecha a Area e elimina os arquivos de apoio criados em disco.
	TBOS->(DbCloseArea())
	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
	ShellExecute( "Open", "taskkill.exe", "/f /im:neto32.exe ", "c:\", 0 )
return

static function FGetAtu()
	FWMsgRun(, {|| FAtuFila() },"", "Atualizando..." )
return

static function FGetTransf()
	FTrfItAmr()
return

static function FAtuFila()
	Local cmd	:= ""

	cmd := ;
	" Select  ZZD_NUM, ZZD_COD, (SELECT TOP 1 LK_CODBAR FROM SLK010 (NOLOCK) WHERE LK_CODIGO= ZZD_COD) AS ZZD_EAN, "	+ CRLF + ;
	" B1_DESC, ZZD_QUANT, ZZD_DATA, ZZD_HORA, ZZD.R_E_C_N_O_ as RECNO " 												+ CRLF + ;
	" FROM ZZD010 ZZD (NOLOCK) "																						+ CRLF + ;
	" inner join SB1010 (NOLOCK) on ZZD_COD = B1_COD "																	+ CRLF + ;
	" where "																										    + CRLF + ;
	" ZZD_FILIAL = '" + cFilAnt + "' "																					+ CRLF + ;
	" and ZZD.D_E_L_E_T_ = ' ' "																						+ CRLF + ;
	" and SB1010.D_E_L_E_T_ = ' '  "																					+ CRLF + ;
	" order by ZZD.R_E_C_N_O_ "

	TCQUERY cmd NEW ALIAS "TBL"
	DbSelectArea("TBL")
	TBL->(DBGOTOP())

	If Select("TBOS") <> 0
		TBOS->(DbCloseArea())
	EndIf

	cArq := Criatrab(_stru, .T.)
	DBUSEAREA(.t.,,cArq, "TBOS")

	aItBrw := {}
	aadd(aItBrw, "EAN             CODIGO          DESCRICAO                                                    QUANT")
	aadd(aItBrw, "")

	while TBL->(!EOF())
		DbSelectArea("TBOS")
		RecLock("TBOS",.T.)

		TBOS->ZZD_NUM	:= TBL->ZZD_NUM
		TBOS->ZZD_COD	:= TBL->ZZD_COD
		TBOS->ZZD_EAN	:= TBL->ZZD_EAN
		TBOS->B1_DESC	:= TBL->B1_DESC
		TBOS->ZZD_QUANT	:= TBL->ZZD_QUANT
		TBOS->ZZD_DATA	:= dtoc(stod(TBL->ZZD_DATA))
		TBOS->ZZD_HORA	:= TBL->ZZD_HORA
		TBOS->ZZD_RECNO := TBL->RECNO
		MsunLock()

		aadd(aItBrw, TBL->ZZD_EAN + " " + TBOS->ZZD_COD + " " +  TBOS->B1_DESC + " " + PADL(cValtoChar(TBOS->ZZD_QUANT), 6, "0") )

		TBL->(DbSkip())
	enddo
	TBL->(DbCloseArea())

	TBOS->(DbGoTop())
	oMark:oBrowse:Refresh()
return

static function getStruct()
return{;
{"OK"			,"C"	,2		,0		},;
{"ZZD_NUM"		,"C"	,6		,0		},;
{"ZZD_COD"		,"C"	,15		,0		},;
{"ZZD_EAN"		,"C"	,13		,0		},;
{"B1_DESC"		,"C"	,60		,0		},;
{"ZZD_QUANT"	,"N"	,4		,0		},;
{"ZZD_DATA"		,"C"	,10		,0		},;
{"ZZD_HORA"		,"C"	,8		,0		},;
{"ZZD_RECNO"	,"N"	,8		,0		};
}

static function getMasks()
return {;
{ "OK"			,, " X"				,"@!"},;
{ "ZZD_NUM"		,, "Orcamento"		,"@!"},;
{ "ZZD_COD"		,, "Produto"		,"@!"},;
{ "ZZD_EAN"		,, "Ean"			,"@!"},;
{ "B1_DESC"		,, "Desc"			,"@!"},;
{ "ZZD_QUANT"	,, "Qt"				,"@999"},;
{ "ZZD_DATA"	,, "Data"			,"@"},;
{ "ZZD_HORA"	,, "Hora"			,"@!"},;
{ "ZZD_RECNO"	,, "RECNO"			,"@!"};
}
/*static function FArrayToCMD(aA)
Local cmd	:= ""
Local i		:= 0
for i:= 1 to len(aA) -1
cmd += aA[i] + ", "
next
cmd += aA[len(aA)] + ". "
return cmd
*/
static function fMarcaDesmarca()
	lCheck := !lCheck
	DbSelectArea("TBOS")
	TBOS->(DbGoTop())

	while TBOS->(!eof())
		RecLock("TBOS",.F.)
		if lCheck
			TBOS->OK := cMark
		else
			TBOS->OK := ""
		endIf
		MsunLock()
		TBOS->(dbSkip())
	endDo
	TBOS->(dbGoTop())
	oMark:oBrowse:Refresh()
return

Static Function Disp()
	RecLock("TBOS",.F.)
	If Marked("OK")
		TBOS->OK := cMark
	Else
		TBOS->OK := ""
	Endif
	MsUnlock()
	oMark:oBrowse:Refresh()
Return()

Static function FGetItCol()
	Local _b1_cod	:= ""
	Local _b1_desc	:= ""
	Local _b1_quant := ""
	Local cArq 		:= "C:\Smartclient\Contagem.txt"
	Local cLinha	:= ""
	local aItens	:= {}
	Local cSemCad	:= ""

	nvalor :=  FT_FUse(cArq)

	if nValor = -1
		u_mErro("Não foi possivel ler o arquivo do coletor (C:\Smartclient\Contagem.txt)")
		Aadd(aItens, {.F.,'0000000000',"","" } )
		return aItens
	endIf
	FT_FGOTOP()
	while !FT_FEOF()
		cLinha:=  FT_FReadLn()
		if !vazio(cLinha)
			_b1_cod := u_cfGtB1cod(Substr(cLinha, 01,13), .F.)
			_b1_quant := Substr(cLinha, 15, 06)

			if !Vazio(_b1_cod)
				_b1_desc := Posicione("SB1", 1, xFilial("SB1")+ _b1_cod, "B1_DESC")
				Aadd( aItens, {'T.', AllTrim(_b1_cod), _b1_desc, val(_b1_quant)}  )
			else
				cSemCad += " - " + _b1_cod + CRLF
			EndIf
		endIf
		FT_FSkip()
	EndDo
	FT_FUse()

	Ferase(cArq)

	if !vazio(cSemCad)
		cSemCad := "Os itens abaixo não são cadastrados no sistema: " + CRLF + cSemCad
		u_mErro(cSemCad)
	EndIf
return aItens

static function FgetToExc()
	Local aRes	:= {}
	TBOS->(dbGoTop())
	while TBOS->(!eof())
		If TBOS->OK <> " "
			aadd(aRes,TBOS->ZZD_RECNO)
		endif
		TBOS->(dbSkip())
	Enddo
	TBOS->(dbGoTop())
return aRes

static function FgetItMark()
	Local aRes	:= {}
	Local nPos	:= 0
	local i		:= 1
	TBOS->(dbGoTop())
	while TBOS->(!eof())
		If TBOS->OK <> " "
			nPos := aScan(aRes, {|x| x[2] = TBOS->ZZD_COD})

			if nPos <> 0
				aRes[nPos, 4] += TBOS->ZZD_QUANT
			else
				aadd(aRes, {'T.', TBOS->ZZD_COD, TBOS->B1_DESC, TBOS->ZZD_QUANT, TBOS->ZZD_RECNO, TBOS->ZZD_NUM}   )
			endIf
		endif
		i++
		TBOS->(dbSkip())
	Enddo
	TBOS->(dbGoTop())
return aRes

Static function FValidaContagem(aItNFe, aItCol)
	Local i
	Local nAux		:= 0
	local oReport 	:= nil
	Local aErr		:= {}
	Local nErros	:= 0
	local cMsg		:= ""

	// Comparar os itens que tem  na query e que nao tem no coletor e a divergencia
	for i:= 1 to len(aItNFe)
		nAux := Ascan( aItCol, {|x| AllTrim(x[2]) = Alltrim(aItNFe[i,2])} )
		if nAux > 0
			if aItNfe[i,4] <> aItcol[nAux, 4]
				aadd(aErr, {aItNfe[i,2], aItNfe[i,3], "Marcado: " + padl(cValToChar(aItNfe[i,4]), 3, "0") + " Bipado: " + padl(cValToChar(aItcol[nAux, 4]), 3, "0") } )
				aItNFe[i,1] := .F.
				aItcol[nAux, 1] := .F.
				nErros++
			endIf
		else
			nErros++
			aadd(aErr, {aItNfe[i,2], aItNfe[i,3], "- Bipado mas não selecionado."} )
		endIf
	next

	// comparar os itens que tem na bipagem e nao tem na query
	for i:=1 to len(aItCol)
		nAux := Ascan( aItNFe, {|x| AllTrim(x[2]) = Alltrim(aItCol[i,2])} )
		if nAux = 0
			aadd(aErr, {aItCol[i,2], aItCol[i,3],  "- Não bipado" } )
			nErros++
		endIf
	next

	if nErros > 0
		cMsg := "Encontrei erros na comparação da bipagem com o que foi marcado: " + CRLF + CRLF
		for i:=1 to len(aErr)
			cMsg +=  "- " + AllTrim(aErr[i,1]) + " " + substr(aErr[i,2], 01, 20) + aErr[i,3] + CRLF
		Next
		u_mErro(cMsg)
	else
		cMsg := "Ok, o bipado bate com o que você marcou para transferir."
		u_mExclama(cMsg)
	endIf
return (nErros = 0)

static function FTrfItAmr()
	Local aItBip:= {}
	Local aItGrd:= {}
	Local i		:= 1
	Local cMsg

	cMsg	:= ;
	"A tela agora vai validar a contagem antes de fazer a transferência."	+ CRLF +;
	"Coloque o coletor na base para baixar os itens bipados"				+ CRLF +;
	"Quando fizer isso, clique em no botão SIM "
	if lUsaCol = .T.
		If u_mQuestion(cMsg) = .F.
			return
		endIf
	endIf

	// pega os itens  marcados
	aItGrd := FgetItMark()

	if Len(aItGrd) = 0
		u_mExclama("Nenhum item selecionado.")
		return
	endif

	if lUsaCol = .T.
		aItBip := FGetItCol()
		if (aItBip[1, 2] = "0000000000")
			return
		endIf
		
		if FValidaContagem(aItGrd, aItBip) = .F.
			return
		endIf
		
	endIf

	// se nao deu erro entao ele vai transferir
	for i:= 1 to  Len(aItGrd)
		Ftransfere(aItGrd[i, 2], aItGrd[i, 4], LOCORIG, LOCDEST, aItGrd[i, 5], aItGrd[i, 6])
	next

	u_mExclama("Processo finalizado...")

	// ao terminar, ele atualiza
	FGetAtu()
return

// Executa a transferencia
Static function Ftransfere(cProd, nQt, cArmOrig, cArmDest, cRecNo, cNum)

	Local nCusto	:= u_getPcCusto(cProd)
	Local cGrupo	:= Posicione("SB1",1, XFILIAL("SB1") + cProd, "B1_GRUPO")

	DbSelectArea("SD3")
	DbSetOrder(1)

	iif ( !vazio(cNum), cNum := "u_CFTAM(), orçamento: " + cNum, cNum := "")

	// inserir o REGISTRO  de saida
	recLock("SD3", .T.)
	SD3->D3_FILIAL	:= cFilAnt
	SD3->D3_TM		:= "501" //"999"
	SD3->D3_COD		:= cProd
	SD3->D3_UM		:= "UN"
	SD3->D3_YLOJA	:= ""
	SD3->D3_LOCAL	:= cArmOrig
	SD3->D3_QUANT	:= nQt
	SD3->D3_CF		:= "RE4"
	SD3->D3_GRUPO	:= cGrupo
	SD3->D3_DOC		:= ""
	SD3->D3_EMISSAO	:= DATE()
	SD3->D3_CUSTO1	:= nCusto
	SD3->D3_CC		:= ""
	SD3->D3_SEGUM	:= "CX"
	SD3->D3_QTSEGUM	:= 0
	SD3->D3_TIPO	:= "ME"
	SD3->D3_USUARIO	:= cUserName
	SD3->D3_CHAVE	:= "E0"
	SD3->D3_YOBS	:= cNum
	Msunlock()

	// inserir entrada no armazem destino
	recLock("SD3", .T.)
	SD3->D3_FILIAL	:= cFilAnt
	SD3->D3_TM		:= "001"  // "499"
	SD3->D3_COD		:= cProd
	SD3->D3_UM		:= "UN"
	SD3->D3_YLOJA	:= ""
	SD3->D3_LOCAL	:= cArmDest
	SD3->D3_QUANT	:= nQt
	SD3->D3_CF		:= "DE4"
	SD3->D3_GRUPO	:= cGrupo
	SD3->D3_DOC		:= ""
	SD3->D3_EMISSAO	:= DATE()
	SD3->D3_CUSTO1	:= nCusto
	SD3->D3_CC		:= ""
	SD3->D3_SEGUM	:= "CX"
	SD3->D3_QTSEGUM	:= 0
	SD3->D3_TIPO	:= "ME"
	SD3->D3_USUARIO	:= cUserName
	SD3->D3_CHAVE	:= "E9"
	SD3->D3_YOBS	:= cNum
	Msunlock()

	SD3->(DbcloseArea())

	// ajustar o saldo do estoque armazem saida
	DbSelectArea("SB2")
	DbSetOrder(1)
	if DbSeek(cFilAnt + cProd + cArmOrig)
		RecLock("SB2", .F.)
		SB2->B2_QATU	-= nQt
		SB2->B2_VATU1	:= SB2->B2_QATU * B2_CM1
	else
		u_mErro("Houve erro ao atualizar o saldo do armazem saída, informe a TI, item: " + cProd )
	endIf
	MsUnlock()

	// ajustar o saldo do estoque armazem entrada
	if DbSeek(cFilAnt + cProd + cArmDest)
		RecLock("SB2", .F.)
		SB2->B2_QATU	+= nQt
		SB2->B2_VATU1	:= SB2->B2_QATU * B2_CM1
	else
		RecLock("SB2", .T.)
		nPcCusto 		:= U_getPcCusto(cProd)
		SB2->B2_FILIAL	:= cFilAnt
		SB2->B2_COD		:= cProd
		SB2->B2_LOCAL	:= cArmDest
		SB2->B2_QATU	:= nQt
		SB2->B2_CM1		:= nPcCusto
		SB2->B2_VATU1	:= SB2->B2_QATU * B2_CM1
	endIf
	MsUnlock()
	SB2->(DbCloseArea())

	FRemItFila(cRecNo)
return

static function FchItFila()
	Local aIt	:= FgetToExc()
	Local i		:= 1

	if len(aIt)= 0
		u_mErro("Nenhum item selecionado.")
		return
	endif

	cmd := " Deseja mesmo remover os "+ cValToChar(len(aIt))+ " itens marcados da fila de abastecimento ? " + CRLF + ""

	if u_mQuestion(cmd) = .T.
		for i:= 1 to len(aIt)
			FRemItFila(aIt[i])
		next
	endIf

	// atualiza a fila
	FGetAtu()
return

static function FRemItFila(nRec)
	// remover da tabela de fila de abastecimento
	DbSelectArea("ZZD")
	ZZD->(DbGoTo(nRec))
	RecLock("ZZD", .F.)
	ZZD->(DbDelete())
	MsUnlock()
	ZZD->(DbcloseArea())
return

static function FDeforigDest()
	Local cOrig  	:= LOCORIG
	Local cDest	 	:= LOCDEST
	Local aPergs 	:= {}
	Local aret 		:= {}

	aret 		:= {}
	aAdd( aPergs ,{1, "Local Origem:", cOrig, "@!", '.T.', "", ".T.", 30, .T.})
	aAdd( aPergs ,{1, "Local Destino:", cDest, "@!", '.T.', "", ".T.", 30, .T.})

	If ParamBox(aPergs,"", aRet,,,,,,,"",.T.,.T.)

		if u_mQuestion("Deseja alterar os parâmetros de armazém origem e destino?" + CRLF + "A opção altera somente os locais origem/destino enquanto a tela estiver aberta") = .T.
			LOCORIG := aRet[1]
			LOCDEST := aRet[2]
		endIf
	EndIf
return

Static function lerArq()
	Local _b1_cod 	:= ""
	Local _b1_quant := ""
	local aItens  	:= {}
	Local cSemCad 	:= ""

	Local aPergs	:= {}
	Local aRet		:= {}
	Local cArq 		:= ""
	Local i			:= 0

	aAdd( aPergs ,{6, "Arquivo Texto:", space(500), "!@", ".T.", ".T.", 90, .T., "Arquivo TXT|*TXT"})
	If ParamBox(aPergs, "Importar arq Coletor",aRet,,,,,,,"",.F.,.F.)

		nvalor :=  FT_FUse(aRet[1])

		if nValor = -1
			u_mErro("Não foi possivel ler o arquivo:" + aRet[1])
			return
		endIf

		FT_FGOTOP()
		while !FT_FEOF()
			cLinha		:=  FT_FReadLn()
			_b1_cod 	:= u_cfGtB1cod(Substr(cLinha, 01, 13), .F.)
			_b1_quant 	:= Substr(cLinha, 15, 06)

			if !Vazio(_b1_cod)
				_b1_desc := Posicione("SB1", 1, xFilial("SB1")+ _b1_cod, "B1_DESC")
				Aadd( aItens, {.T., _b1_cod, _b1_desc, _b1_quant}  )
			else
				cSemCad += " - " + _b1_cod + CRLF
			EndIf
			FT_FSkip()
		EndDo
		FT_FUse()

		if !vazio(cSemCad)
			cSemCad := "Os  itens abaixo não são cadastrados no sistema, não vou importar: " + CRLF + cSemCad
		else

			DbSelectArea("ZZD")
			DbSetOrder(1)

			for i:= 1 to len(aItens)

				if DbSeek(cFilAnt + space( TamSx3("ZZD_NUM")[1]) + aItens[i,2])
					RecLock("ZZD", .F.)
					ZZD_FILIAL	:= ZZD_FILIAL
					ZZD_QUANT	+= Val(aItens[i,4])
					ZZD_DATA	:= Date()
					ZZD_HORA	:= Time()
				else
					RecLock("ZZD", .T.)
					ZZD_FILIAL	:= cFilAnt
					ZZD_COD		:= aItens[i,2]
					ZZD_QUANT	:= val(aItens[i,4])
					ZZD_DATA	:= Date()
					ZZD_HORA	:= Time()
					msUnlock()
				EndIf
			Next
		EndIf
	else
		return
	endIf
	Alert("Proceso finalizado, clique em listar para atualizar.")
return

static function FImpFila()
	Local oRep := RpDefDif()
	oRep := RpDefDif()
	oRep:PrintDialog()
return
// definicao do relatorio de erros
Static function RpDefDif()
	Local oReport	:= Nil
	Local oSection1	:= Nil
	//	Local oBreak
	//	Local oFunction

	oReport := TReport():New(" CFTAM ", "Produtos na fila de abastecimento", "", {|oReport| RPrtDif(oReport)}, "Itens na fila")
	oreport:nfontbody := 9
	oReport:SetLandscape()
	oReport:SetTotalInLine(.F.)

	oSection1:= TRSection():New(oReport, "CABECA", {"ZNR"}, , .F., .T.)
	TRCell():New(oSection1,"ZNR_DESC"   ,"TZ9","Itens solicitados"		,"@!", 200)

	oReport:SetTotalInLine(.F.)
return oReport

static function RPrtDif(oReport)
	Local oSection1 := oReport:Section(1)
	Local i

	oSection1:Init()

	oSection1:Cell("ZNR_DESC"):SetValue( "--------------------------------------------------------------------------------")
	oSection1:Printline()

	for i:=1 to len(aItBrw)

		oSection1:Cell("ZNR_DESC"):SetValue(aItBrw[i])
		oSection1:Printline()
	Next
	oReport:SkipLine()

	oSection1:Cell("ZNR_DESC"):SetValue( "--------------------------------------------------------------------------------")
return