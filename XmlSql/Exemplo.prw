#INCLUDE "PROTHEUS.CH"
User function ex1

  Local oXmlSql	:= XmlSql():new("arquivo.XML") // carrega o objeto XmlSQL
	 
	Local cmd	:= oXmlSql:cSQL("getCliente", {"000001", "01"}) // metodo para "carregar o comando SQL"
  
return "Ok"
