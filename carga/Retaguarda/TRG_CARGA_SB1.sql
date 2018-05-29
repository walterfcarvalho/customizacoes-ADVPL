/*
	Exemplo de trigger para uma tabela compartilhada por filial.
	@waltercarvalho
	01/08/2017
*/


create TRIGGER [dbo].[TRG_CARGA_SB1] ON [dbo].[SB1010] 
FOR INSERT, UPDATE
AS 
BEGIN
	DECLARE @RECNO INT			-- vai pegar o recno do registro da ZZZ
	DECLARE @NREG INT			-- pega o numero do registro alterado
	DECLARE @DATA INT			-- data da alteracao
	DECLARE @HORA VARCHAR(08)	-- hora da alteracao
	DECLARE @TB VARCHAR(03)		-- Pega o nome da tabela
   	
	-- pegue a data hora e a tabela alterada
	SELECT  @HORA  = SUBSTRING(CONVERT(VARCHAR,SYSDATETIME()),12,8), 
          @DATA  = CONVERT(VARCHAR(8), GETDATE(), 112), @TB = 'SB1'

	-- processamos as alteracoes via cursor	
	DECLARE CurIns CURSOR FAST_FORWARD FOR select R_E_C_N_O_ from INSERTED
	OPEN CurIns
	FETCH NEXT FROM CurIns INTO @NREG

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS( SELECT * FROM ZZ0010 WHERE ZZ0_TABELA= @TB AND  ZZ0_NREG = @NREG )
		BEGIN
			SELECT @RECNO = (SELECT ISNULL(MAX(R_E_C_N_O_),1)+1 FROM ZZ0010)

			INSERT ZZ0010 (ZZ0_FILIAL, ZZ0_TABELA, ZZ0_NREG, ZZ0_DATA, ZZ0_HORA, D_E_L_E_T_, R_E_C_N_O_) 
			VALUES        (  '01    ',        @TB,    @NREG,    @DATA,    @HORA,        ' ',    @RECNO ) 
		END
		ELSE
			UPDATE ZZ0010 SET ZZ0_DATA = @DATA, ZZ0_HORA = @HORA
			WHERE ZZ0_TABELA = @TB AND ZZ0_NREG   = @NREG

		FETCH NEXT FROM CurIns INTO @NREG
	END
	CLOSE CurIns
	DEALLOCATE CurIns
END