#include 'apwizard.ch'
#include 'dg.ch'
#include 'parmtype.ch'
#include 'protheus.ch'
#include "RWMAKE.CH"
#include "TBICONN.CH"
#include 'TOPCONN.CH'

/*/{Protheus.doc} DGALTVD
Tela para  ALTERAR vendedor de uma venda
@author valter
@since 22/11/2018
@version 1

/*/
user function DGMONCARG() // u_DGMONCARG()
	Local cArq
	Local aCpoBro 	:= {}
	Local aCores	:= {}
	Local lEnd		:= .T.
	Local oProcess	:= MsNewProcess():New({ |lEnd| atualizar(@oProcess, @lEnd) }, "Consultando nas lojas selecionadas", "Consultar carga na loja", .F.)
	Local oFont 	:= TFont():New('Courier new',,-18,.T.)
	Local oSay1	
	Local oGroup1

	private _stru 	    := {}
	Private cMark       := GetMark()
	Private oMark
	Private lInverte    := .F.
	Private lCheck	    := .F.
	Private oCheck
	private nLojas	    := 0	
	private cDhUltCarg := ""

	//cMark   := {}	

	aAdd(aCores,{" TBOS->LEGENDA == 'OK' ", "BR_VERDE"	 })
	aAdd(aCores,{" TBOS->LEGENDA == 'SC' ", "BR_CINZA"	 })
	aAdd(aCores,{" TBOS->LEGENDA == 'DS' ", "BR_VERMELHO"})

	aadd( _stru, {"OK"				,"C"	,2		,0	})
	aadd( _stru, {"LEGENDA"			,"C"	,2		,0	}) 
	aadd( _stru, {"FILIAL"			,"C"	,10		,0	})
	aadd( _stru, {"DT_ULTATU"		,"C"	,10		,0	})
	aadd( _stru, {"HR_ULTATU"		,"C"	,08		,0	})
	aadd( _stru, {"SERVIDOR"		,"C"	,20		,0	})
	aadd( _stru, {"PORTA_REPL"		,"C"	,04		,0	})
	aadd( _stru, {"AMBIENTE_R"      ,"C"	,20		,0	})

	aadd(aCpoBro, { "OK"			,, ""								,"@!"})
	aadd(aCpoBro, { "FILIAL"		,, "Filial " 						,"@!"})  
	aadd(aCpoBro, { "DT_ULTATU"		,, "Data da ultima atualizacao"		,"@!"})
	aadd(aCpoBro, { "HR_ULTATU"		,, "Hora da ultima atualizacao"		,"@!"}) 

	cArq := Criatrab(_stru, .T.)
	DBUSEAREA(.t.,,cArq, "TBOS")

	DEFINE MSDIALOG oDlg TITLE "Monitor de cargas para as lojas - DGMONCARG" From 9,0 To MsAdvSize()[6], 800 PIXEL

	oGroup1 := TGroup():New(02, 02, 28, 150, "Data e hora da última carga", oDlg,,,.T.)


	cDhUltcarg 	:= getDataCargaGerada()
	oSay1 		:= TSay():New( 12, 12,{|| cDhUltcarg },oDlg,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE, 300, 90)

	oMark := MsSelect():New("TBOS","OK","",aCpoBro, @lInverte, @cMark,{040,002,450,395},,,,,aCores)

	oMark:bMark := {| | Disp()}

	@ 003, 300 BUTTON oBtgera PROMPT "Prep. carga"  SIZE 042, 022 OF oDlg ACTION ( preparaCarga() ) PIXEL
	@ 003, 350 BUTTON oBtgera PROMPT "Cons. Lojas"  SIZE 042, 022 OF oDlg ACTION ( getDataCargaGerada(), chamaCarga(), oMark:oBrowse:Refresh(), Alert("Terminado") ) PIXEL

	@ 031, 002 SAY oSay1 PROMPT "F12 Para informações sobre carga. " SIZE 075, 022 OF oDlg COLORS 0, 16777215 PIXEL

	oCheck := TCheckBox():Create( oDlg,{||}, 031, 150,'Marcar/Desmarcar Todas.', 075, 022,,{|| fMarcaDesmarca(),  },,,,,,.T.,,,)

	SET KEY VK_F12 TO
	SETKEY(VK_F12,{|| texto() })

 	ListaLojas()

	//Exibe a Dialog
	ACTIVATE MSDIALOG oDlg CENTERED

	//Fecha a Area e elimina os arquivos de apoio criados em disco.
	TBOS->(DbCloseArea())
	Iif(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
return


static function chamaCarga()
	Local oProcess	:= MsNewProcess():New({ |lEnd| atualizar(@oProcess, @lEnd) }, "Consultando nas lojas selecionadas", "Consultar carga na loja", .F.)
	oProcess:Activate()	
return .t.


static function preparaCarga()
	Local aRes := {}
	FWMsgRun(, {||  aRes := TCSPExec( "sto_gera_carga_dg")   },"", "rodando procedure sto_gera_carga_dg, aguarde..." )
	cDhUltcarg 	:= getDataCargaGerada()	
return


static function ListaLojas()
	Local cmd

	cmd := ;
	" select * FROM ZNR010 WHERE ATIVA= '1' ORDER BY ZNR_FILIAL "

	TCQUERY cmd NEW ALIAS "TBL"
	DbSelectArea("TBL")
	TBL->(DBGOTOP())

	If Select("TBOS") <> 0
		TBOS->(DbCloseArea())
	EndIf

	cArq := Criatrab(_stru, .T.)
	DBUSEAREA(.t.,,cArq, "TBOS")

	while TBL->(!EOF())
		DbSelectArea("TBOS")
		RecLock("TBOS",.T.)

		TBOS->LEGENDA		:= "SC"
		TBOS->FILIAL		:= allTrim(TBL->ZNR_FILIAL)
		TBOS->DT_ULTATU		:= ""
		TBOS->HR_ULTATU		:= ""

		TBOS->AMBIENTE_R	:=  allTrim(TBL->AMBIENTE_REPLICA)
		TBOS->PORTA_REPL	:=  allTrim(TBL->PORTA_REPLICA)
		TBOS->SERVIDOR		:=  allTrim(TBL->SERVIDOR)

		MsunLock()
		TBL->(DbSkip())
		nLojas++
	enddo
	TBL->(DbCloseArea())

	TBOS->(DbGoTop())
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


static function atualizar(oProcess)
	Local oProcess
	Local lEnd		:= .F.
	Local cParUD 	:= "CT_UCD"
	Local cParUH 	:= "CT_UCH"
	Local aAux		:= {}
    local cDtLocal  := dtos(ctod(substr(cDhUltcarg, 01,10)))
    Local cHrLocal  := substr(cDhUltcarg, 12, 08)
    Local cDtRemot  := ""
    Local cHrremot  := ""

	oProcess:SetRegua1(nLojas)
	TBOS->(DbGoTop())
	oMark:oBrowse:Refresh()
	while TBOS->(!eof())
		oProcess:IncRegua1("Loja: " +  TBOS->FILIAL)
		sleep(10)		

		if 	TBOS->OK = cMark
			aAux := ;
			getx6remoto(@oProcess, allTrim(TBOS->FILIAL), allTrim(TBOS->SERVIDOR), allTrim(TBOS->PORTA_REPL), allTrim(TBOS->AMBIENTE_R), {"x6", cParUD, cParUH} )

			RecLock("TBOS", .F.)

			if len(aAux) = 0
				TBOS->DT_ULTATU	:= ""
				TBOS->HR_ULTATU	:= ""
			else
				TBOS->DT_ULTATU	:= dtoc(sTod(aAux[1]))
				TBOS->HR_ULTATU	:= aAux[2]

                cDtRemot := dtos(ctod(substr(TBOS->DT_ULTATU, 01,10)))
                cHrRemot := TBOS->HR_ULTATU

                if cDtRemot + " " + cHrRemot  >= cDtLocal + " " + cHrLocal
					TBOS->LEGENDA := 'OK'
				else
					TBOS->LEGENDA := 'DS'
				endif

			endif
		endif	
		TBOS->(dbSkip())
	endDo
	TBOS->(dbGoTop())
	oMark:oBrowse:Refresh()
return


static function getx6remoto(oProcess, cLj, cServer, nPort, cEnv, aInfRemota)
    Local aRes := {}
	Local xValor
	Local cFuncao := "U_getX6"

	oRpcSrv := TRPC():New(cEnv) 
	oProcess:SetRegua2(4)

	oProcess:IncRegua2("IP: " + cServer + ":" + nPort + " Ambiente: " + cEnv)

  	If ( oRpcSrv:Connect( cServer, Val(nPort), 05 ) )

	    oRpcSrv:CallProc("RPCSetType", 3)

		oProcess:IncRegua2("Prepare enviroment: " + cEnv)

        oRpcSrv:CallProc("RPCSetEnv" , "01", cLj, Nil, Nil, "SIGALOJA", "RCP", {"SX6"})

		 
		if oRpcSrv:CallProc("Findfunction", cFuncao) = .T.
	        if aInfRemota[1] = "x6"
				xValor := oRpcSrv:CallProc(cFuncao, aInfRemota[2])
				IF VALTYPE(xValor) = "C"
			       	aadd(aRes, xValor)
				ENDIF	

				xValor := oRpcSrv:CallProc(cFuncao, aInfRemota[3])
				if VALTYPE(xValor) = "C"
			       	aadd(aRes, xValor)
		  		endif    
			endif	  
		else
	        ares := {}   	
			msgInfo(" - Fonte " + cFuncao + " não compilado no host: " + cServer + CRLF	 ) 
		endif

    	oRpcSrv:Disconnect()

    else
        ares := {}   	
    Endif  
return aRes


static function getDataCargaGerada()
	Local cRes := ""
	Local cmd := "select CT_UCD, CT_UCH from CARGA_LOJA"

	TCQUERY cmd NEW ALIAS "TBL"
	DbSelectArea("TBL")
	
	cRes := dtoc(sTod(TBL->CT_UCD)) + ' ' + TBL->CT_UCH

	TBL->(DbCloseArea())
return cRes


static function texto()
	Local cmd := ""

	cmd+=; 
	" - A lista de filiais com os dados de conexão são guardadas na tabela ZNR010"  			+ CRLF + ; 
	" - A carga local será gerada pela procedure sto_gera_carga_dg "							+ CRLF + ; 
	" - A data e hora da ultima carga gerada localmente estão na tabela CARGA_LOJA  "			+ CRLF + ; 
	" - A data/ hora da ultima carga nas lojas estão nos parametros CT_UCD e CT_UCH " 			+ CRLF + ; 
	" "
	u_mExclama(cmd)
return .T.

//01/01/2019