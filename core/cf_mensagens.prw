#include 'protheus.ch'
#include 'parmtype.ch'
#include 'CF.ch'

User function mErro(cMensagem) 
	MessageBox( CRLF + cMensagem + CRLF, CNMEMP, MB_OK + MB_ICONHAND)
return 

User function mQuestion(cMensagem)
	Local lret := .F.
 	if (MessageBox( CRLF + cMensagem + CRLF, CNMEMP , MB_YESNO + MB_ICONASTERISK) = IDYES)
 		lret := .T.
 	EndIf	 
return lret

User function mExclama(cMensagem)
  	MessageBox( CRLF + cMensagem + CRLF, CNMEMP, MB_OK + MB_ICONEXCLAMATION)
return 

User function mAviso(msg)
//	Aviso("", msg, {"OK"}, 1)
//	Aviso("", msg, {"OK"}, 2)
	Aviso("", msg, {"OK"}, 3)
return