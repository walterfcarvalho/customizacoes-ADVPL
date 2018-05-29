#include 'apwizard.ch'
#include 'CF.ch'
#include 'parmtype.ch'
#include 'TOPCONN.CH'
#include 'protheus.ch'
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

user function cfChCargaInc() //u_cfChCargaInc()
	Local cPerg 	:= PADR("CHCARGACF", 10)
	Local cmd 		:= 	"   Deseja efetuar uma carga de todas as alterações das tabelas:" 	+ CRLF
	Local aTbs		:= 	{}
	Local oProcess
	Private oHp := Hash():new("\_cargaCF.ini", .F.)

	AjustaSX1(cPerg)

	If Pergunte(cPerg,.T.)
		putMv("CF_UCD", dtos(MV_PAR01))
		putMv("CF_UCH", "00:00:00")
	else
		return
	endif

	aTbs := 	oHp:getHashs()

	for i:=1 to len(aTbs)
		cmd += " - " + Posicione("SX2", 1, oHp:gpc(aTbs[i], 2), "X2_NOME") + CRLF
	next

	if u_mQuestion(cmd)
		oProcess := MsNewProcess():New({|lEnd| cmd := u_cfCargaInc(cFilAnt,, @oProcess, @lEnd) },"","Carga de dados", .F.)
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

		fPuthelp(cPerg + "01", "Informar a partir de que data que baixar as atualizações " )
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
