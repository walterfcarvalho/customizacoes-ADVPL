#include 'protheus.ch'
#include 'parmtype.ch'
#include "fileio.ch"

Class Hash

	Data aLinhas
	Data cTp

	Method New(cArq, lUsaDirCF, cTipo) Constructor
	Method cSql(cIdx, aParam)		   // retorna o comando SQL formatado
	Method gpl(cNomeParam, nNumCampo ) // para retornar numeros
	Method gpc(cNomeParam, nNumCampo ) // para retornar caracteres
	Method getHashs()

	Method LoadHash(cArq)
	Method getCampo(nNumCampo, cLinha, cTipo )
	Method getPosIni(nCampo, cLin)
	Method getArray(nCampo, cLin)
	Method getArrayN(nCampo, cLin)
	Method LimpaStr(cStr)
	Method LoadByIni(cArq, lUsaDirCF)
	Method loadByXml(cArq)

EndClass

method LimpaStr(cStr) class Hash
	Local aCaract 	:= {}
	Local i			:= 1

	aCaract := {char(09), char(10), char(13), " "}
	for i := 1 to len(aCaract)
		cStr := StrTran(cStr, aCaract[i], "")
	Next
return cStr

Method  cSql(cParam, aParams) class Hash
	Local cLinha 	:= ""
	Local i 		:= 0
	Local cAux		:= ""

	cLinha := ::gpc(cParam, 1)

// colocar os valores dos parametros no lugar
	for i:= 1 to len(aParams)
		if at('?', cLinha) > 0
			if Type("aParams[i]") <> "C"
				cAux := cValToChar(aParams[i])
			else
				cAux := aParams[i]
			endIf
			cLinha :=   Stuff ( cLinha,  AT('?', cLinha), 1, cAux )
		EndIF
	Next
	// quebra as linhas
	While (AT('|', cLinha) > 0)
		cLinha :=   Stuff ( cLinha,  AT('|', cLinha), 1, CRLF )
	EndDo
	
	/*
	grava arquivo de log com o nome da funcao
	*/
	 u_cfLog(cLinha)
return cLinha

Method New(cArq, lUsaDirCF, cTipo ) class Hash
	Local cLinha
	Local _array := {}
	Local nPosMarcador := 0

	::aLinhas	:= {}
	iif (Vazio(cTipo) .or. cTipo = "ini", ::cTp := "ini", "xml")

	if ::cTp = "ini"
		::LoadByIni (cArq, lUsaDirCF)
	else
		::LoadByXml (cArq)
	endIf

Return Self

Method LoadByXml (cArq) class hash
	Local cMetodos	:= ""
	Local aStrings	:= {}

	Local cReplace	:= "_"
	Local cErros	:= ""
	Local cAvisos 	:= ""
	Local cMsg    	:= ""
	Local i			:= 1
	Local oLido
	Local cErr

	If !File( "\_casaFreitas\" + cArq, 0, .F. )
		cErr := "Arquivo resource no diretorio _casafreitas não existe:" + "\_casaFreitas\" + cArq
		u_mErro(cErr)
		conOut (cErr)
		Return
	EndIf

	oLido := XmlParser(MemoRead("\_casaFreitas\" + cArq), cReplace, @cErros, @cAvisos)

	if cErros <> "" .or. cAvisos <> ""
		cErr := "Houve problema ao carregar o Xml do arquivo " + "\_casaFreitas\" + cArq + CRLF + "Erros : " + cErros + CRLF + "Avisos: " + cAvisos
		conOut(cErr)
		u_mErro(cErr)
		return
	endIf

	cMetodos := oLido:_xml:_Metodos:TEXT

	// retirar enter tab, ho
	cMetodos  := ::LimpaStr(cMetodos)

	aStrings := StrTokArr(cMetodos, "," )

	for i:= 1 to  len(aStrings)
		Aadd( ::aLinhas,   { aStrings[i], XmlChildEx(oLido:_xml, "_" + Upper(aStrings[i])):Text }  )
	next
return

Method LoadByIni (cArq, lUsaDirCF) class hash
	if cArq <> ""
		if lUsaDirCF
			If !File( "\_casaFreitas\" + cArq, 0, .F. )
				u_mErro("Arquivo resource no diretorio _casafreitas não existe:" + "\_casaFreitas\" + cArq)
				Return
			EndIf
			nValor :=  FT_FUse("\_casaFreitas\" + cArq)
		else
			nValor :=  FT_FUse(cArq)
		endIf

		if nValor = -1
			conOut("Nao consegui abrir o arquivo, erro:" + cValToChar(nValor) )
		endIf

		FT_FGOTOP()
		while !FT_FEOF()
			cLinha:=  FT_FReadLn()
			if At("~", cLinha) > 0
				nPosMarcador := At("~", cLinha)

				Aadd( ::aLinhas,   {  Substr(cLinha, 1, nPosMarcador-1), Substr(cLinha, nPosMarcador+1) }  )
			EndIf
			FT_FSkip()
		EndDo
		FT_FUse()
	endIf
return

Method getHashs()  class Hash
	Local aHashs := {}
	for i:=1 to len(::aLinhas)
		aadd(aHashs, AllTrim(::aLinhas[i,1]))
	next
return aHashs

Method gpl(cNomeParam, nNumCampo ) class Hash

	Local nValor := 0
	Local i := 1
	Local j := 0

	for i:=1 to len(::aLinhas) step 1
		if ::aLinhas[i][1] = cNomeParam
			j:=i
			exit
		EndIf
	Next

	if J = 0
		Alert("Não encontrei o resource:" +  cNomeParam + " Param: " + cValToChar(nNumCampo)  )
		conOut("Nao achei o resource "  +  cNomeParam + " Param: " + cValToChar(nNumCampo)  )
		nValor := "-1"
	else
		nvalor := ::getCampo(nNumCampo, ::aLinhas[j][2], 'N')
	EndIf
return nValor

Method gpc(cNomeParam, nNumCampo ) class Hash
	Local cValor := ""
	Local i := 1
	Local j := 0

	for i:=1 to len(::aLinhas) step 1
		if AllTrim(::aLinhas[i][1]) = AllTrim(cNomeParam)
			j:=i
			exit
		EndIf
	Next

	if J = 0
		Alert("Não encontrei o resource:" + cNomeParam)
		conOut("Nao achei o resource " + cNomeParam)
		nValor := ""
	else

		if ::cTp = "ini"
			cvalor := Self:getCampo(nNumCampo, ::aLinhas[j][2], 'C')
		else
			cvalor := Self:aLinhas[j][2]
		endIf
	EndIf
return cValor

Method getCampo(nNumCampo, cL, cTipo) class Hash
	Local  nTamanho
	Local  nPosI
	Local  res
	nTamanho := 1

	nPosI := ::getPosIni(nNumCampo, cL);

	while ((nTamanho+nPosI) <= len(cL)) .AND. ( substr(cL, (nPosI+nTamanho), 01) <> ':' )
		nTamanho := nTamanho +1
	endDo

	if cTipo == 'C'
		res := Substr(cL, nPosI+1, nTamanho-1)
	else
		res := val(Substr(cL, nPosI+1, nTamanho-1))
	EndIf
return res


Method getPosIni(nCampo, cLin) class Hash
	nPosIni := 0
	nCpAtual := 1
	while ( (nPosIni <= Len(cLin)) .and. (nCpAtual <= nCampo) )
		nPosIni := nPosIni +1
		if substr(cLin, nPosIni, 1) = ':'
			nCpAtual := nCpAtual +1
		Endif
	EndDo

	return nPosIni
return


Method getArray(nCampo, cLin) class Hash
	Local aRes 		:= {}
	Local nPos 		:= 1
	Local nPosIni	:= 1

	cLin := ::gpc(cLin, nCampo )

	while nPos <> 0

		nPos := At(  ",", cLin, nPosIni)

		if nPos <> 0
			aadd(aRes, Substr(cLin, nPosIni, (nPos - nPosIni)  ) )
		else
			aadd(aRes, Substr(cLin, nPosIni)   )
		endIf

		nPosIni := nPos+1
	endDo

return  aRes


Method getArrayN(nCampo, cLin) class Hash
	Local i:= 	1
	Local aRs := ::getArray(nCampo, cLin)

	for i:=1 to Len(aRs)
		aRs[i] := val(aRs[i])
	next
return aRs
