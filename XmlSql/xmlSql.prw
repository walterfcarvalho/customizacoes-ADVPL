#include 'protheus.ch'
#include 'parmtype.ch'
#include "fileio.ch"
#include 'TOPCONN.CH'

#DEFINE _CDIR_ 	"\_xmlSql\"
#DEFINE CRLF  	CHAR(13) + CHAR(10)

Class xmlSql

Data oXml

Method cSql(cIdx, aParam)		   	// retorna o comando SQL formatado
Method getArray(cIdx, aParam)		// retorna o resultado do comando SQL dentro de um array
Method getStru(cIdx, aParam)		// retorna um array com a estrutuda dos campos da query (DbStruct())
Method aArrC(cIdx, aParam)          //

Method gpC(cNomeParam, nNumCampo ) 	// para retornar caracteres
Method gpN(cNomeParam, nNumCampo ) 	// para retornar numero
Method hSQLExec(cIdx, aParam)		// recebe um id do no xml e executa um TCSQLExec
Method New(cArq) Constructor		// construtor da classe


getVlNo(cIdNo)
// metodos usados internamente
Method avisar(cMsg)
Method getCampo(nNumCampo, cLinha, cTipo )
Method getPosIni(nCampo, cLin)
Method getArrayN(nCampo, cLin)
Method limpaStr(cStr)
Method getVlNo(cIdNo)
EndClass

/*/{Protheus.doc} New
Construtor da classe XmlSql
@return oXmlSql
/*/
Method New(cArq) class XmlSql
	Local cReplace	:= "_"
	Local cErros	:= ""
	Local cAvisos 	:= ""
	Local cMsg    	:= ""

	If !File( _CDIR_ + cArq, 0, .F. )
		Self:avisar("Arquivo resource no diretorio "+ _CDIR_ + " não existe:" + _CDIR_ + cArq)
		Return
	EndIf

	Self:oXml := XmlParser(MemoRead(_CDIR_ + cArq), cReplace, @cErros, @cAvisos)

	if (cErros <> "") .or. (cAvisos <> "")
		Self:avisar("Houve problema ao carregar o Xml do arquivo " + _CDIR_ + cArq + CRLF + "Erros : " + cErros + CRLF + "Avisos: " + cAvisos)
		return
	endIf
return

/*/{Protheus.doc} LimpaStr
//  Remove de uma String os caracteres  char(09), char(10), char(13) e " " de uma string
//	@param  cStr : String a ser tratada
//  @return String
/*/
method LimpaStr(cStr) class xmlSql
	Local aCaract 	:= {}
	Local i			:= 1

	aCaract := {char(09), char(10), char(13), " "}
	for i := 1 to len(aCaract)
		cStr := StrTran(cStr, aCaract[i], "")
	Next
return cStr

/*/{Protheus.doc} cSql
// monta a String SQL para o comando
@return String:		String com o  comando SQL.
/*/
Method  cSql(cIdNo, aParams) class XmlSql
	Local cLinha 	:= ""
	Local i 		:= 1
	Local nQp

	cLinha 	:= Self:getVlNo(cIdNo)

	// colocar os valores dos parametros no lugar
	for i:= 1 to len(aParams)
		if at('?', cLinha) > 0
			if Type("aParams[i]") <> "C"
				cAux := cValToChar(aParams[i])
			else
				cAux := aParams[i]
			endIf
			cLinha :=   Stuff ( cLinha,  AT('?', cLinha), 1, cAux )
		Endif
	Next

	// quebra as linhas
	While (AT('|', cLinha) > 0)
		cLinha :=   Stuff ( cLinha,  AT('|', cLinha), 1, CRLF )
	EndDo

	//se enviado o caractere "@" antes da tabela, ele troca o nome da tabela
	//pelo nome da tabela no ADVPL usando retSqlName()
	i := AT('@', cLinha)
	while (i > 0)

		nQp:= i + 1
		while (!substr(cLinha, nQp, 1) $ " ." + char(13) + char(10) + char(09))  .and. (nQp <= len(cLinha))
			nQp++
		endDo

		cLinha :=   Stuff ( cLinha, i, nQp - i, RetSqlName(substr(clinha,i+1, 3)))
		i := AT('@', cLinha)
	endDo

return cLinha


/*/{Protheus.doc} gpN
Retorna o valor numerico de um campo contido dentro de um nó.
Dentro do mesmo nó pode-se colocar vários valores numericos separados por
Ex: Se no xml há o nós <no1>:1:12:3:4:</no>,  oXmlSql:gpl("no1", 1) = 1, oXmlSql:gpl("no1", 2) = 12

@return numeric, valor gravado no nó
@param cNomeParam:	 String, cId do nó no arquivo XML
@param nNumCampo:	 numeric, número do parâmetro a ser consultado.
/*/
Method gpN(cNomeParam, nNumCampo ) class XmlSql
	Local nValor := 0
	nValor := val(Self:gpc(cNomeParam, nNumCampo ))
return nValor

/*{Protheus.doc} gpc
Retorna o valor String de um campo contido dentro de um nó.
Dentro do mesmo nó pode-se colocar vários valores String separados por Self:
Ex: Se no xml há o nós <no1>:Advpl:é:muito:legal:</no>,  oXmlSql:gpl("no1", 1) = "Advpl", oXmlSql:gpl("no1", 4) = "legal"
@return caracter, valor String gravado no nó
@param cNomeParam:	 String, cId do nó no arquivo XML
@param nNumCampo:	 numeric, número do parâmetro a ser consultado.
*/
Method gpC(cNomeParam, nNumCampo ) class XmlSql
	Local cLinha 	:= Self:getVlNo(cIdNo)
	Local cRes	:= ""
	
	cRes :=  Self:getCampo(nNumCampo, cLinha, "C")
return cRes

/*/{Protheus.doc} getCampo
Metodo interno para pegar o valor de um Campo dentro do No XML
@return Dependendo de cTipo pode retornar String ou numeric
@param nNumCampo, numeric: 	numero do campo dentro do no, sendo o primeiro campo é 1
@param cL, characters, Representa a string completa do no
@param cTipo, characters, Tipo do Parametro que se quer ler, pode ser "C" ou "N"
/*/
Method getCampo(nNumCampo, cL, cTipo) class XmlSql
	Local  nTamanho
	Local  nPosI
	Local  res
	nTamanho := 1

	nPosI := Self:getPosIni(nNumCampo, cL);

	while ((nTamanho+nPosI) <= len(cL)) .AND. ( substr(cL, (nPosI+nTamanho), 01) <> ':' )
		nTamanho := nTamanho +1
	endDo

	if cTipo == 'C'
		res := Substr(cL, nPosI+1, nTamanho-1)
	else
		res := val(Substr(cL, nPosI+1, nTamanho-1))
	EndIf
return res

/*/{Protheus.doc} getPosIni
Metodo interno para pegar ocaractere que representa a posicao inicial de uma linha
@return numeric
@param nCampo, numeric, numero do campo que deseja retornar
@param cLin, characters, String completa que se deseja retornar
/*/
Method getPosIni(nCampo, cLin) class XmlSql
	Local nPosIni	:= 0
	Local nCpAtual	:= 1
	while ( (nPosIni <= Len(cLin)) .and. (nCpAtual <= nCampo) )
		nPosIni := nPosIni +1
		if substr(cLin, nPosIni, 1) = ':'
			nCpAtual := nCpAtual +1
		Endif
	EndDo

	return nPosIni
return

/*/{Protheus.doc} getArray
Retorna um array de String a partir de um campo dentro de um no XML
@return aArray com a Sring constante no campo dentro de um nó XML
@param cIdNo, Valor do nó do Xml, as Strings deverão etar separadas com ","
/*/
Method aArrC(cIdNo) class XmlSql
	Local aRes 		:= {}
	Local nPos 		:= 1
	Local nPosIni	:= 1

	cLin :=  Self:getVlNo(cIdNo)

	while nPos <> 0

		nPos := At(",", cLin, nPosIni)

		if nPos <> 0
			aadd(aRes, Substr(cLin, nPosIni, (nPos - nPosIni)  ) )
		else
			aadd(aRes, Substr(cLin, nPosIni)   )
		endIf

		nPosIni := nPos + 1
	endDo
return  aRes

/*/{Protheus.doc} getArrayN
Retorna um array de numeric  a partir de um campo dentro de um no XML
@return aArray com a Sring constante no campo dentro de um nó XML
@param nCampo, Numero do campo dentro de cLin
@param cLin, characters, linha completa dentro no nó XML
@type function
/*/
Method getArrayN(nCampo, cLin) class XmlSql
	Local i:= 	1
	Local aRs := Self:getArray(nCampo, cLin)

	for i:=1 to Len(aRs)
		aRs[i] := val(aRs[i])
	next
return aRs

/*/{Protheus.doc} hSQLExec
//
@since 25/09/2018
@version 1.0
@return Se o comando for executado com sucesso, retorna .T.
@param cIdx, characters, Id do nó do comando no arquivo XML
@param aParam, array, Parâmetros que serão passados para montar a String do comando Sql
@type function
/*/
Method hSQLExec(cIdx, aParam) class XmlSql
	Local lRes	:= .F.
	Local cmd	:= Self:cSQL(cIdx, aParam)

	if Vazio(cmd)
		lRes := .F.
	else
		lRes := TCSQLExec(cmd)
	endif

	if lRes < 0
		Alert("Classe:XmlSql" + CRLF + "Ocorreu um erro na execução do comando" + CRLF + cmd)
	endIf

return lRes

/*/{Protheus.doc} avisar
Metodo auxiliar para exibir erros
@return vazio
@param cMsg, mensagem a ser exibida
/*/
Method avisar(cMsg) class XmlSql
	ConOut(cMsg)
	Alert(cMsg)
return
resultado do dentro de um array
return		// retorna um array com a estrutuda dos campos da query (DbStruct())
Method getArray(cIdx, aParam) class XmlSql		// retorna o          //
	Local cmd	:= Self:cSql(cIdx,aParam)
	Local aStru	:= {}
	Local aIt	:= {}
	Local aRes	:= {}
	Local i		:= 1
	Local cTb	:= "ZYXZXA"

	TCQUERY cmd NEW ALIAS (cTb)
	DbSelectArea(ctb)
	aStru :=  (cTb)->(dbStruct())
	(cTb)->(DBGOTOP())

	while !(cTb)->(eof())
		aIt := {}
		for i:=1 to len(aStru)
			aadd(aIt, (cTb)-> &(aStru[i,1]))
		Next

		if len(aIt) == 1
			aadd(aRes, aIt[1])
		else
			aadd(aRes, aIt)
		endif
		(cTb)->(DbSkip())
	endDo
	(cTb)->(DbcloseArea())
return aRes

Method getVlNo(cIdNo) class class XmlSql
	Local cLinha
	Local cAux		:= "_" + upper(cIdNo)
	Local oNo 		:= XmlChildEx(Self:oXml:_XML, cAux)

	cLinha 	:= ""
	if valType(oNo) == "U"
		Self:avisar("Não achei o resource " + cIdNo)
	else
		cLinha := oNo:TEXT
	endif
return cLinha

Method getStru(cIdx, aParam) class XmlSql
	Local cmd	:= Self:cSql(cIdx,aParam)
	Local cTb	:= "ZYAXZ"
	Local aRr

	TCQUERY cmd NEW ALIAS (cTb)
	DbSelectArea(ctb)
	aRr :=  (cTb)->(dbStruct())
	(cTb)->(DbcloseArea())
return aRr


