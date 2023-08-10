-- Cursor
DECLARE @SeriDeud char(4), @NumDeud char(8), @AñoAcad char(4), @PeriAcad char(2), @NumCuota char(2),
    @Comprobante varchar(50),  @NumDI varchar(15), @importe_en_deuda decimal(15,2), @fecha datetime, @importe_en_comprobante decimal(15,2), @tipo_comprobante_emitido varchar(50);

-- Cursor
DECLARE C_TEMP_DEUDA  CURSOR FOR   
SELECT top 1 c.SeriDeud, c.NumDeud, c.AñoAcad, c.PeriAcad, c.NumCuota, a.Comprobante, a.NumDI, a.importe_en_deuda, a.fecha, a.importe_en_comprobante from SGA.Temp.anularCuotas  a 
    INNER JOIN SGA.dbo.PensionesxCobrar b on a.Comprobante = b.Comprobante
    INNER join SGA.dbo.Deudas c on b.SeriDeud = c.SeriDeud AND b.NumDeud = c.NumDeud


DECLARE @usuario_Serie CHAR(4) = '8888';
DECLARE @serie_Recibo CHAR(4) = 'R026';
DECLARE @serie_Boleta CHAR(4) = 'B026';
DECLARE @serie_NotaCredito CHAR(4) = 'BA26';


OPEN  C_TEMP_DEUDA;

FETCH NEXT FROM  C_TEMP_DEUDA INTO @Comprobante, @NumDI, @importe_en_deuda, @fecha, @importe_en_comprobante, @tipo_comprobante_emitido;
WHILE @@FETCH_STATUS = 0
BEGIN

     -- Numeracion Operacion
    DECLARE @NumOperChar CHAR(9);
    SELECT @NumOperChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuario_Serie;

     -- Especialidad, sede y programa
    DECLARE @CodEsp VARCHAR(4), @SedeEst VARCHAR(2), @Programa CHAR(2);
    
    SELECT top 1 @CodEsp = CodEspe, @SedeEst = sed_id, @Programa = MAC_id  FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @NumDI;

    IF EXISTS (SELECT *  FROM SGA.Temp.SGA.Temp.anularCuotas where Comprobante not like '[0-9]%' ) BEGIN

        -- Numeracion Nota credito
        DECLARE @NumNotaCreditoChar char(8);
        SELECT @NumNotaCreditoChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @NumDI AND SerieElec = @serie_NotaCredito;

        select top 1 * from SGA.Temp.anularCuotas  a 
        INNER JOIN SGA.dbo.PensionesxCobrar b on a.Comprobante = b.Comprobante
        INNER join SGA.dbo.Deudas c on b.SeriDeud = c.SeriDeud AND b.NumDeud = c.NumDeud
        where b.Comprobante = @Comprobante
        
        -- Operacion
        INSERT INTO SGA.dbo.Operacion
        (
            SeriOper,NumOper,TipDI,NumDI,TipOper,
            FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
            Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
            Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
        )VALUES
        (
            @usuario_Serie, @NumOperChar, '12', @NumDI, '01', -- condonacion
            CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, @importe_en_comprobante, '1', 1, 'OPERACION DE CANCELACION DEUDA CON NOTA DE CREDITO',
            'ADMINISTRADOR', '----', @CodEsp, @SedeEst, @Programa, '0',
            30, @serie_NotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
        );

        INSERT INTO SGA.dbo.DetOper
        (
            SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
            PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
            codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
        )
        VALUES
        (
            @usuario_Serie, @NumOperChar, '001', '6595257', 'D', -@importe_en_comprobante, @DeudaNumCuota, @MatriculaAnioMax,
            @MatriculaPeriodoMax, TRIM(@DeudaSeri)+TRIM(@DeudaNum), 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), '', 1,
            '----', '----', '7', @serie_NotaCredito+@NumNotaCreditoChar, @Comprobante, '3'
        );

        -- Nota credito
        INSERT INTO SGA.dbo.Notas_Cred_Deb
        (
            SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
            Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
        )
        VALUES
        (
            @usuario_Serie, @NumOperChar, CONVERT(date, GETDATE(), 120), @serie_NotaCredito, @NumNotaCreditoChar, 'COMPROBANTE AFECTADO '+@Comprobante,
            @importe_en_comprobante, 'NC', '01', '01', @OperSeriOper, @OperNumOper
        );


        UPDATE SGA.dbo.NumeracionFE SET 
            NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @NumNotaCreditoChar) + 1 ))), 8)
        WHERE serie = @usuario_Serie AND SerieElec = @serie_NotaCredito;

        UPDATE SGA.dbo.Usuarios Set 
            NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  
        Where Serie = @usuario_Serie;



    END
    ELSE BEGIN

    END


    FETCH NEXT FROM  C_TEMP_DEUDA INTO @TipoComp, @Comprobante, @NumDI, @importe_en_deuda, @fecha, @importe_en_comprobante, @tipo_comprobante_emitido;

END

CLOSE  C_TEMP_DEUDA;
DEALLOCATE  C_TEMP_DEUDA;


select * from SGA.Temp.anularCuotas

