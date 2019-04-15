#include 'apwizard.ch'
//#include 'CF.ch'
#include 'parmtype.ch'
#include 'TOPCONN.CH'
#include 'protheus.ch'
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

#define CRLF char(13) + char(10)
#define cROTINA  "cargaLoja() "

user function cfChCargaInc() //	u_cfChCargaInc()
	Local i
	Local cReplace, cErros, cAvisos
	Local cPerg 	:= PADR("CHCARGACF", 10)
	Local cmd 		:= 	"   Deseja efetuar uma carga de todas as alterações das tabelas:" 	+ CRLF
	Local aCampos	:= 	{}
	Local oProcess
	Local oXml


	cReplace 	:=  ""
	cErros 		:=  ""
	cAvisos 	:= ""

	AjustaSX1(cPerg)

	If Pergunte(cPerg,.T.)
		putMv("CT_UCD", dtos(MV_PAR01))
		putMv("CT_UCH", "00:00:00")
	else
		return
	endif

	oXml := XmlParser(MemoRead("\_cargaLoja.xml"), cReplace, @cErros, @cAvisos)
	if (cErros <> "") .or. (cAvisos <> "")
		u_mErro("Houve problema ao carregar o Xml do arquivo \_cargaLoja.xml"  + CRLF + "Erros : " + cErros + CRLF + "Avisos: " + cAvisos)
		return	
	endIf

	for i:=1 to len(oxml:_xml:_carga)
		aadd(aCampos, Limpa(oxml:_xml:_carga[i]:_tabela:text)  )
	Next

	for i:=1 to len(aCampos)
		cmd += " - " + aCampos[i] + " - " + Posicione("SX2", 1, aCampos[i], "X2_NOME") + CRLF
	next

	if u_mQuestion(cmd)
		oProcess := MsNewProcess():New({|lEnd| cmd := u_cfCargaInc(cFilAnt, nil, @oProcess, @lEnd) },"","Carga de dados", .F.)
		oProcess:Activate()

		u_mExclama(cmd)
	endIf

return

Static Function AjustaSX1(cPerg)
	DbSelectArea("SX1")
	DbSetOrder(1)

	if !DbSeek(cPerg + "01")
		recLock("SX1", .T.)
		SX1->X1_GRUPO 	:= cPerg
		SX1->X1_ORDEM	:= "01"
		SX1->X1_PERGUNT := "Data inicial das alterações."
		SX1->X1_TIPO	:= "D"
		SX1->X1_VARIAVL := "MV_PAR01"
		SX1->X1_TAMANHO	:= 8
		SX1->X1_DECIMAL	:= 0
		SX1->X1_GSC		:= "G"
		SX1->X1_VAR01	:= "MV_PAR01"
		SX1->X1_HELP	:= cPerg + "01"
		MsUnlock()

		fPuthelp(cPerg + "01", "Informar a partir de que data que baixar as atualizações! " )
	endif
Return

Static Function fPutHelp(cKey, cHelp, lUpdate)
	Local cFilePor  := "SIGAHLP.HLP"
	Local nRet      := 0
	Default cKey    := ""
	Default cHelp   := ""
	Default lUpdate := .F.
     
	If Empty(cKey) .Or. Empty(cHelp)
		Return
	EndIf
     
	nRet := SPF_SEEK(cFilePor, cKey, 1)
     
    //Se não encontrar, será inclusão
	If nRet < 0
		SPF_INSERT(cFilePor, cKey, , , cHelp)
	Else
		If lUpdate
			SPF_UPDATE(cFilePor, nRet, cKey, , , cHelp)
		EndIf
	EndIf
Return

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
