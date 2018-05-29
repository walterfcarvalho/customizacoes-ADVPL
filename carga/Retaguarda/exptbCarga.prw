#include 'parmtype.ch'
#include 'protheus.ch'
#include "RWMAKE.CH"
#include "TBICONN.CH"
#include 'TOPCONN.CH'

#define MB_OK               0
#define MB_OKCANCEL         1
#define MB_ICONHAND			16
#define MB_ICONQUESTION     32
#define MB_ICONEXCLAMATION 	48
#define MB_ICONASTERISK     64
#define MB_YESNO			4
#define IDOK			    1
#define IDCANCEL		    2
#define IDYES			    6
#define IDNO			    7
#define CNMEMP				"NomeDaEmpresa"
#define CRLF				CHAR(13) + CHAR(10)

/*/{Protheus.doc} expTbCarga
Tela para  preparar os registros de carga para o PDV

@author Valter Carvalho
@since 22/05/2015
@version 1
@type function

/*/
user function expTbCarga()
	Local oCbTb
	Local oCbOper
	Local oGet2
	Local oFont
	Private cFiltro
	Private oCbCampos
	Private aCampos
	Private cNmTb
	Private cNmCampo
	Private cPrefTb
	Private aTb
	Private aNmOper
	Private cTbZZ0

	cNmTb 	:= space(3)
	cFiltro := space(255)

	cNmOper := "="
	aCampos	:= {}
	cPrefTb	:= ""

	oFont :=  TFont():New("MS Sans Serif",,-12,.T.)
	If Select("SX2") == 0
		RPCSetType(3)
		RPCSetEnv("01","010101",Nil,Nil,"LOJA")
	Endif
	cTbZZ0  := "ZZ0"
	aTb		:= getTables()
	aNmOper	:= {"Igual", "Diferente", "Maior que", "Menor que", "Maior/igual que", "Menor/igual que"}

	DEFINE MSDIALOG oDlg TITLE "Prepara registros para exportação - EXPTBCARGA" From 9,0 To 120, 500 PIXEL

	@ 003, 005 SAY oSay1 PROMPT "Tabela(CF_LTCPDV)" SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
	oCbTb :=  TComboBox():New(010, 005,{|u|if(PCount()>0,cNmTb:=substr(u,1,3),cNmTb)}, aTb, 150, 20, oDlg,,{|| getCamposTb()},,,,.T.,ofont,,,,,,,,'cNmTb')

	@ 030, 005 SAY oSay1 PROMPT "Campo:(em branco p/ todos)" SIZE 080, 007 OF oDlg COLORS 0, 16777215 PIXEL
	oCbCampos :=  TComboBox():New(036, 005,{|u|if(PCount()>0,cNmCampo:=u,cNmCampo)}, aCampos, 70, 20,oDlg,,{||   },,,,.T.,ofont,,,,,,,,'cNmCampo')

	@ 030, 80 SAY oSay1 PROMPT "Operador" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	oCbOper :=  TComboBox():New(036, 80,{|u|if(PCount()>0,cNmOper:=u,cNmOper)}, aNmOper, 50, 20,oDlg,,{||   },,,,.T.,ofont,,,,,,,,'cNmCampo')

	@ 030, 135 SAY oSay1 PROMPT "Expresão:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
	oGet2		:= TGet():New( 036, 135,{|u| If(PCount()>0,cFiltro:=u,cFiltro)},oDlg,100,13,'@!',{|| .T. },,,oFont,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cFiltro",,)

	@ 003, 192 BUTTON oBtgera PROMPT "Gerar"  SIZE 042, 022 OF oDlg ACTION geraReg() PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
return

static function getCamposTb()
	DbSelectArea("SX3")
	DbSetOrder(1)
	if !DbSeek(cNmTb)
		Alert("Tabela " + cNmTb + " não existe." )
		return
	endIf

	aCampos := {}

	cPrefTb := substr(SX3->X3_CAMPO, 1, at("_", SX3->X3_CAMPO ) -1)

	aadd(aCampos, "")
	While !Eof() .And. (x3_arquivo == cNmTb)
		aadd(aCampos, AllTrim(SX3->X3_CAMPO) + " - " + SX3->X3_TITULO)
		SX3->(DbSkip())
	endDo

	ASort(aCampos, , , {|x,y|x < y})
	oCbCampos:SetItems(aCampos)
	oCbCampos:refresh()
return

static function lTbComp()
	DbSelectArea("SX2")
	DbSetOrder(1)
	DbSeek(cNmTb)
return SX2->X2_MODO == "C"

static function removeAspas(cStr)
	cStr := StrTran(AllTrim(cStr), '"', "")
	cStr := StrTran(cStr,  "'", "")
return AllTrim(cStr)

static function getCmd()
	Local cQuery
	Local cWhere
	Local cTpVar
	Local xCampo
	Local aOper

	aOper :=  {"=", "<>", ">", "<", ">=", "<="}
	cWhere := ""
	cQuery := "select " + cPrefTb + "_FILIAL, R_E_C_N_O_ as NREG from " + RetSqlName(cNmTb)

	if !Vazio(cNmCampo)
		cNmCampo := subst(cNmCampo, 1, at(" - ", cNmCampo)-1)
		xCampo := removeAspas(cFiltro)
		cTpVar := Posicione("SX3",2, cNmCampo, "X3_TIPO")

		DO CASE
			CASE cTpVar == "N"
			xCampo :=  xCampo
			CASE cTpVar == "D"
			xCampo :=  dTos(cTod(xCampo))
			OTHERWISE
			xCampo :=  "'" + (xCampo) + "'"
		ENDCASE

		cWhere := " where " + AllTrim(cNmCampo) + " " + aOper[ascan(aNmOper, cNmOper)] + " " +  xCampo
	endif
return cQuery + cWhere

static function geraReg()
	Local cmd
	Local aRecs
	Local i
	Local nCount

	if Vazio(cPrefTb)
		MessageBox( "Selecione uma tabela.", CNMEMP, MB_OK + MB_ICONHAND)
		return
	endif

	nCount	:= 0
	aRecs 	:= {}
	cmd 	:= getCmd()

	CURSORWAIT()

	TCQUERY cmd NEW ALIAS "ZQR"
	ZQR->(DbGoTop())
	while !ZQR->(eof())
		aadd(aRecs, { &(cPrefTb + "_FILIAL"), ZQR->NREG} )
		ZQR->(DbSkip())
		nCount++
	endDo
	ZQR->(DbCloseArea())

	if nCount > 0
		if (MessageBox( "Deseja marcar " + cValToChar(nCount) + " registros ?", CNMEMP, MB_YESNO + MB_ICONQUESTION) <> IDYES)
			CURSORARROW()
			return
		endif
	else
		MessageBox( "Nenhum registro encontrado com esse filtro", CNMEMP, MB_OK + MB_ICONEXCLAMATION)
		CURSORARROW()
		return
	endif

	DbSelectArea(cTbZZ0)
	DbSetOrder(2)
	for i:=1 to len(aRecs)
		if (DbSeek(aRecs[i,1] + cNmTb + cValToChar(aRecs[i,2]))  )
			RecLock(cTbZZ0, .F. )
		else
			RecLock(cTbZZ0, .T. )
		endif

		&((cTbZZ0 + "_FILIAL"))	:= aRecs[i,1]
		&((cTbZZ0 + "_TABELA"))	:= cNmTb
		&((cTbZZ0 + "_NREG")) 	:= aRecs[i,2]
		&((cTbZZ0 + "_DATA")) 	:= DATE()
		&((cTbZZ0 + "_HORA")) 	:= TIME()

		msUnlock()
	Next

	(cTbZZ0)->(DbCloseArea())

	CURSORARROW()

	MessageBox( "Registros preparados: " + cValToChar(nCount), CNMEMP, MB_OK + MB_ICONEXCLAMATION)
return

static function getTables()
	Local cTb
	Local aTb
	Local i

	cTb := GetMV("CF_LTCPDV")
	aTb := StrTokArr2( cTb, "," , .F.)

	for i:= 1 to len(aTb)
		cTb := Alltrim(aTb[i])
		aTb[i] := cTb + "[" + Posicione("SX2", 1, cTb, "X2_MODO") + "] - " + Posicione("SX2", 1, cTb, "X2_NOME")
	Next
return aTb
