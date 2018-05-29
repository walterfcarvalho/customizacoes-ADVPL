#include 'protheus.ch'
#include 'parmtype.ch'

user function dtHrToN(cData, cHora)
 	Local  nData := 0

	if !vazio(cData)
		nData += val(Substr(cData,1,4)) * 365 * 86400 	// ano
		nData += val(Substr(cData,5,2)) * 31  * 86400	// mes
		nData += val(Substr(cData,7,2)) * 1	  * 86400	// dia
	endif

	if !vazio(cHora)
		nData += (val(Substr(cHora,1,2)) * 60 * 60) 	// hora
		nData += (val(Substr(cHora,4,2)) * 60)  		// min
		nData += (val(Substr(cHora,7,2)) * 1)  			// seg
	endIf
return nData