
ALTER procedure sto_gera_carga_dg
as 
begin
	-- EXEC sto_gera_carga_dg
	-- SELECT * FROM CARGA_LOJA

	declare @CT_UCD VARCHAR(8)
	declare @CT_UCH VARCHAR(8)
/*
	SELECT @CT_UCD = max(B0_MSEXP) FROM SB0010 (NOLOCK) -- WHERE B0_FILIAL <> '' AND B0_PRV1 <> '' AND D_E_L_E_T_ = ''
	select @CT_UCH = max(B0_HREXP) FROM SB0010 (NOLOCK) WHERE B0_MSEXP = @CT_UCD
*/

	-- pegue a data e hora atual
	select @CT_UCD = CONVERT(VARCHAR(08), getdate() + '00:20:00', 112), @CT_UCH = CONVERT(VARCHAR(08), getdate() + '00:20:00', 108) 

	UPDATE CLK010 SET CLK_MSEXP = @CT_UCD, CLK_HREXP = @CT_UCH	WHERE  CLK_MSEXP = ''
	PRINT  CONCAT ('registros da CLK',  @@ROWCOUNT )


	UPDATE SA1010 SET A1_MSEXP = @CT_UCD, A1_HREXP = @CT_UCH	WHERE  A1_MSEXP = ''
	PRINT  CONCAT ('registros da SA1',  @@ROWCOUNT )


	UPDATE SA3010 SET A3_MSEXP = @CT_UCD, A3_HREXP = @CT_UCH	WHERE  A3_MSEXP = ''
	PRINT  CONCAT ('registros da SA3',  @@ROWCOUNT )
	

	UPDATE SB0010 SET B0_MSEXP = @CT_UCD, B0_HREXP = @CT_UCH	WHERE  B0_MSEXP = ''
	PRINT  CONCAT ('registros da SB0',  @@ROWCOUNT )


	UPDATE SB1010 SET B1_MSEXP = @CT_UCD, B1_HREXP = @CT_UCH	WHERE  B1_MSEXP = ''
	PRINT  CONCAT ('registros da SB1',  @@ROWCOUNT )


	UPDATE SLK010 SET LK_MSEXP = @CT_UCD, LK_HREXP = @CT_UCH	WHERE  LK_MSEXP = ''
	PRINT  CONCAT ('registros da SLK',  @@ROWCOUNT )

	-- marca na tabela a data e hora da carga
	UPDATE CARGA_LOJA SET CT_UCD = @CT_UCD, CT_UCH = @CT_UCH
	PRINT  CONCAT ('Data:', @CT_UCD ,  ' Hora:', @CT_UCH)	


end
