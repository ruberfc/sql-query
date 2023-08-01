CREATE PROCEDURE SP_PROCESO_CONDONACION(
    @codigo_est varchar(15)
)AS
BEGIN

    DECLARE @usuario_Serie char(4) = '8888';
    DECLARE @serie_Boleta char(4) = 'B026';
    DECLARE @serie_NotaCredito char(4) = 'BA26';


    -- Total notas curso y total cursos matriculados
    DECLARE @TotalNotasCurso BIGINT, @TotalCursosMatriculados BIGINT;

    
    -- Obtener ultimo año de matricula del estudiante Nta_Nota
    DECLARE @MatriculaAnioMax VARCHAR(4);
    SELECT @MatriculaAnioMax = MAX(Mtr_Anio) from DBCampusNet.dbo.Nta_Nota where Est_Id = @codigo_est


    -- Obtener ultimo periodo de matricula del estudiante Nta_Nota
    DECLARE @MatriculaPeriodoMax VARCHAR(4);
    SELECT @MatriculaPeriodoMax = MAX(Mtr_Periodo) from DBCampusNet.dbo.Nta_Nota WHERE Est_Id = @codigo_est and Mtr_Anio = @MatriculaAnioMax;


    SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE Mtr_Anio = @MatriculaAnioMax AND
        Mtr_Periodo = @MatriculaPeriodoMax AND
        Nta_Promedio = 'im' AND
        Est_Id = @codigo_est;
    

    IF @TotalNotasCurso = 0 AND @TotalCursosMatriculados = 0 BEGIN
        RETURN 'No se encontro registro de notas';
    END
    ELSE BEGIN

        IF @TotalNotasCurso = @TotalCursosMatriculados  AND  @TotalNotasCurso > 0 AND @TotalCursosMatriculados > 0 BEGIN
            

            -- Numeracion operacion Usuarios
            DECLARE @NumOperChar CHAR(9);
            SELECT @NumOperChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuario_Serie;
            --SELECT @NumOperChar =  RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, NumOper) + 1 ))), 9) FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;


            -- Especialidad, sede y programa Clientes
            DECLARE @CodEspEst VARCHAR(4), @SedeEst VARCHAR(2), @Programa CHAR(2);
            SELECT top 1 @CodEspEst = CodEspe, @SedeEst = sed_id, @Programa = MAC_id  FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;


            /* Cursor deuda Estudiante */
            DECLARE @DeudaSerie CHAR(4), @DeudaNumeracion CHAR(8), @DeudaCodContab char(14), @DeudaImporte NUMERIC(15,2), @DeudaNumCuota CHAR(2);

            DECLARE C_DEUDA_ESTUDIANTE  CURSOR FOR   
                SELECT SeriDeud, NumDeud, CodContab, Importe, NumCuota
                FROM SGA.dbo.Deudas
                WHERE   AñoAcad = @MatriculaAnioMax AND
                        PeriAcad = @MatriculaPeriodoMax AND
                        NumCuota in ('01', '02', '03', '04', '05') AND  --@DeudaNumCuota AND 
                        CondDeud in (0, 9) and
                        NumDI = @codigo_est;

            OPEN C_DEUDA_ESTUDIANTE;
    
            FETCH NEXT FROM C_DEUDA_ESTUDIANTE INTO @DeudaSerie, @DeudaNumeracion, @DeudaCodContab, @DeudaImporte, @DeudaNumCuota;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                
                IF EXISTS(SELECT * from SGA.dbo.PensionesxCobrar where SeriDeud = TRIM(@DeudaSerie) and NumDeud = TRIM(@DeudaNumeracion) and Comprobante LIKE 'B%' or Comprobante LIKE 'F%') BEGIN 
                    /* COMPROBANTES ELECTRONICOS*/

                    -- Comprobante FE PensionesxCobrar
                    DECLARE @ComprobanteFE varchar(15);
                    SELECT @ComprobanteFE = Comprobante FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@DeudaSerie) AND NumDeud = TRIM(@DeudaNumeracion);

                    -- Numeracion nota credito NumeracionFE
                    DECLARE @NumNotaCreditoChar char(8);
                    SELECT @NumNotaCreditoChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuario_Serie AND SerieElec = @serie_NotaCredito;


                    -- Serie y numeracion Operacion Comprobante FE
                    DECLARE @OperacionSerie char(4), @OperacionNumeracion char(9);
                    SELECT  @OperacionSerie = SeriOper, @OperacionNumeracion = NumOper FROM SGA.dbo.Operacion where Serie_FE+Numero_FE =   TRIM(@ComprobanteFE);


                    /* OPERACION NOTA CREDITO */
                    INSERT INTO SGA.dbo.Operacion
                    (
                        SeriOper,NumOper,TipDI,NumDI,TipOper,
                        FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                        Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                        Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                        CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, -@DeudaImporte, '1', 1, 'RECTIFICACIÓN DE COMPROBANTE EMITIDO '+@ComprobanteFE+' POR DERECHO DE CONDONACIÓN DE DEUDA',
                        'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
                        30, @serie_NotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
                    );


                    /* DETALLE OPERACION NOTA CREDITO */

                    /* Cursor detalle comprobante */
                    -- DECLARE @DeudaSerie CHAR(4), @DeudaNumeracion CHAR(8), @DeudaCodContab char(14), @DeudaImporte NUMERIC(15,2), @DeudaNumCuota CHAR(2);
                    -- select distinct CodigoItem from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200919841'
                    -- select top 10 * from SGA.dbo.DetalleComprobante_Maestra
                    DECLARE @idComprobanteElectronico VARCHAR(20), @idComprobante VARCHAR(20), @CodigoItem INT, @PrecioUnitario DECIMAL(14,2), @TipoImpuesto CHAR(2), @Impuesto DECIMAL(14,2), @TotalVenta DECIMAL(14,2), @Suma DECIMAL(14,2);

                    
                    DECLARE C_DETALLE_COMPROBANTE  CURSOR FOR   
                        SELECT idComprobanteElectronico, idComprobante, CodigoItem, PrecioUnitario, TipoImpuesto, Impuesto, TotalVenta, Suma
                        FROM SGA.dbo.DetalleComprobante_Maestra
                        WHERE  idComprobanteElectronico = TRIM(@ComprobanteFE)
                    OPEN C_DETALLE_COMPROBANTE;
    
                    FETCH NEXT FROM C_DETALLE_COMPROBANTE INTO @idComprobanteElectronico, @idComprobante, @CodigoItem, @PrecioUnitario, @TipoImpuesto, @Impuesto, @TotalVenta, @Suma;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        INSERT INTO SGA.dbo.DetOper
                        (
                            SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                            PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                            codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                        )
                        VALUES
                        (
                            @usuario_Serie, @NumOperChar, '001', '6595257', 'D', -@DeudaImporte, @DeudaNumCuota, @MatriculaAnioMax,
                            @MatriculaPeriodoMax, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                            '----', '1', '7', @serie_NotaCredito+@NumNotaCreditoChar, @ComprobanteFE, '3'
                        );

                        FETCH NEXT FROM C_DETALLE_COMPROBANTE INTO @idComprobanteElectronico, @idComprobante, @CodigoItem, @PrecioUnitario, @TipoImpuesto, @Impuesto, @TotalVenta, @Suma;
                    END

                    CLOSE C_DETALLE_COMPROBANTE;
                    DEALLOCATE C_DETALLE_COMPROBANTE;



                    INSERT INTO SGA.dbo.DetOper
                    (
                        SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                        PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                        codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperChar, '001', '6595257', 'D', -@DeudaImporte, @DeudaNumCuota, @MatriculaAnioMax,
                        @MatriculaPeriodoMax, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                        '----', '1', '7', @serie_NotaCredito+@NumNotaCreditoChar, @ComprobanteFE, '3'
                    );


                    /* CREAR NOTA CREDITO */
                    INSERT INTO SGA.dbo.Notas_Cred_Deb 
                    (
                        SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
                        Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperChar, CONVERT(date, GETDATE(), 120), @serie_NotaCredito, @NumNotaCreditoChar, 'ANULACIÓN DE LA OPERACIÓN '+@ComprobanteFE,
                        @DeudaImporte, 'NC', '01', '01', @OperacionSerie, @OperacionNumeracion
                    );


                    UPDATE SGA.dbo.Usuarios Set NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  Where Serie = @usuario_Serie;


                    -- Numeracion operacion Usuarios
                    DECLARE @NumOperPagoChar CHAR(9);
                    SELECT @NumOperPagoChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuario_Serie;


                    /* OPERACION PAGO DEUDA */
                    INSERT INTO SGA.dbo.Operacion
                    (
                        SeriOper,NumOper,TipDI,NumDI,TipOper,
                        FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                        Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                        Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperPagoChar, '12', @codigo_est, '00',
                        CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, @DeudaImporte, '1', 1, 'PAGO DE DEUDA - CONDONACIÓN',
                        'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
                        30, '', '', 'NC', NULL, NULL, NULL
                    );


                    /* DETALLE OPERACION PAGO DEUDA */
                    INSERT INTO SGA.dbo.DetOper
                    (
                        SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                        PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                        codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperPagoChar, '001', @DeudaCodContab, 'H', @DeudaImporte, @DeudaNumCuota, @MatriculaAnioMax,
                        @MatriculaPeriodoMax, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                        '----', '1', '3', '', '', '3'
                    ); 


                    /*  ACTUALIZAR DEUDA */
                    UPDATE SGA.dbo.Deudas SET 
                        CondDeud = '2', 
                        Observac = 'DERECHO DE CONDONACIÓN DE DEUDA', 
                        DocCanc = @ComprobanteFE, 
                        actualiza = CONVERT(CHAR(1), CAST(ISNULL(actualiza, '0')  AS INT) + 1)
                    WHERE   [AñoAcad] = @MatriculaAnioMax AND
                            PeriAcad = @MatriculaPeriodoMax AND
                            NumCuota = @DeudaNumCuota AND
                            CondDeud in (0,9) AND
                            NumDI = @codigo_est;
                            -- SeriDeud = @DeudaSerie AND NumDeud = @DeudaNumeracion


                    UPDATE SGA.dbo.NumeracionFE SET NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @NumNotaCreditoChar) + 1 ))), 8)where Serie = @usuario_Serie AND SerieElec =  @serie_NotaCredito;

                    UPDATE SGA.dbo.Usuarios Set NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperPagoChar) + 1 ))), 9)  Where Serie = @usuario_Serie;

                    DELETE FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = @DeudaSerie AND NumDeud = @DeudaNumeracion;

                END
                ELSE BEGIN
                    /* COMPROBANTES FISICOS */

                    -- Comprobante no FE PensionesxCobrar
                    DECLARE @ComprobanteNoFE varchar(15);
                    SELECT  @ComprobanteNoFE = Comprobante from SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@DeudaSerie) AND NumDeud = TRIM(@DeudaNumeracion);


                    /* OPERACION PAGO DEUDA */
                    INSERT INTO SGA.dbo.Operacion
                    (
                        SeriOper,NumOper,TipDI,NumDI,TipOper,
                        FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                        Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                        Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperChar, '12', @codigo_est, '00',
                        CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, @DeudaImporte, '1', 1, 'PAGO DE DEUDA - CONDONACIÓN',
                        'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
                        30, '', '', 'NC', NULL, NULL, NULL
                    );


                    /* DETALLE OPERACION PAGO DEUDA */
                    INSERT INTO SGA.dbo.DetOper
                    (
                        SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                        PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                        codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                    )
                    VALUES
                    (
                        @usuario_Serie, @NumOperPagoChar, '001', @DeudaCodContab, 'H', @DeudaImporte, @DeudaNumCuota, @MatriculaAnioMax,
                        @MatriculaPeriodoMax, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                        '----', '1', '3', '', '', '3'
                    );


                    Update SGA.dbo.Deudas SET 
                        CondDeud = '2', 
                        Observac = 'DERECHO DE CONDONACIÓN DE DEUDA',  
                        DocCanc = @ComprobanteNoFE, 
                        actualiza =  CONVERT(CHAR(1), CAST(ISNULL(actualiza, '0')  AS INT) + 1) 
                    WHERE   [AñoAcad] = @MatriculaAnioMax AND
                            PeriAcad = @MatriculaPeriodoMax AND
                            NumCuota = @DeudaNumCuota AND
                            CondDeud in (0,9) AND
                            NumDI = @codigo_est;


                    UPDATE SGA.dbo.Usuarios Set NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  Where Serie = @usuario_Serie;

                    DELETE FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@DeudaSerie) AND NumDeud = TRIM(@DeudaNumeracion)

                END

                FETCH NEXT FROM C_DEUDA_ESTUDIANTE INTO @DeudaSerie, @DeudaNumeracion, @DeudaCodContab, @DeudaImporte, @DeudaNumCuota;

            END

            CLOSE C_DEUDA_ESTUDIANTE;
            DEALLOCATE C_DEUDA_ESTUDIANTE;

            
            -- Numeracion deuda Usuarios
            DECLARE @NewDeudaNumeracion CHAR(8), @NewOperacionNumeracion CHAR(9);
            Select @NewDeudaNumeracion = NumDeud, @NewOperacionNumeracion = NumOper from SGA.dbo.Usuarios where Serie = @usuario_Serie;

            /* CREAR NUEVA DEUDA POR CONDONACION */
            INSERT INTO SGA.dbo.Deudas 
            (
                SeriDeud, NumDeud, FecCarg, CondDeud, TipDI, NumDI,
                CodContab, Importe, FecVenc, TasaMora, TipMoneda, TipCambio,
                NumCuota, AñoAcad, PeriAcad, TipCarg, Observac, Usuario,
                DocCanc, EscPen, TipDoc, cantidad, actualiza, CondDeclarado, Valor
            )
            VALUES 
            (
                @usuario_Serie, @NewDeudaNumeracion, CONVERT(smalldatetime, GETDATE(), 120), '0', '12', @CodEspEst,
                '----', 104, '2023-12-31 00:00:00', 0.0005, '1', 1,
                '', @MatriculaAnioMax, @MatriculaPeriodoMax, '----', 'PAGO POR DERECHO DE CONDONACIÓN DE DEUDA - RESOLUCIÓN N° 0216-2023-CU-UPLA.', 'ADMINISTRADOR',
                @usuario_Serie+@NewOperacionNumeracion, NULL, NULL, NULL, NULL, 0, NULL
            );

            /* OPERACION DE NUEVA DEUDA */
            INSERT INTO SGA.dbo.Operacion
            (
                SeriOper,NumOper,TipDI,NumDI,TipOper,
                FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
            )
            VALUES
            (
                @usuario_Serie, @NewOperacionNumeracion, '12', @codigo_est, '01', -- condonacion
                CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'CARGO DEL DERECHO DE CONDONACIÓN DE DEUDA',
                'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
                30, NULL, Null, NUll, NULL, NULL, NULL
            );


            /* DETALLE DE OPERACION DE NUEVA DEUDA */
            INSERT INTO SGA.dbo.DetOper
            (
                SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
            )
            VALUES
            (
                @usuario_Serie, @NewOperacionNumeracion, '001', '----', 'H', 100, '', @MatriculaAnioMax,
                @MatriculaPeriodoMax, @usuario_Serie+@NewDeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                '----', '1', '3', NULL, NULL, ''
            ),
            (
                @usuario_Serie, @NewOperacionNumeracion, '002', '----', 'H', 4, '', @MatriculaAnioMax,
                @MatriculaPeriodoMax, @usuario_Serie+@NewDeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                '----', '1', '3', NULL, NULL, ''
            );


            UPDATE SGA.dbo.Usuarios Set 
                NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NewOperacionNumeracion) + 1 ))), 9),
                NumDeud = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NewDeudaNumeracion) + 1 ))), 9)
                Where Serie = @usuario_Serie;

            RETURN 'Serie y operacion de deuda ' + @usuario_Serie + ' ' + @NewDeudaNumeracion;

        END
        ELSE BEGIN
            RETURN 'No se hiso impedir en todos los cursos';
        END

    END

    
END


-- SELECT top 10 * from SGA.dbo.PlanContab where c_cuen = '7551011'
-- SELECT top 10 * from SGA.dbo.PlanContab where l_cuen like '%PENSION'
-- select top 10 * from SGA.dbo.Deudas
-- select top 10 * from SGA.dbo.TDo_TipDocumento
-- select top 10 * from SGA.dbo.TipDcto
-- select top 10 * from SGA.dbo.TipCargDeuda
-- select top 10 * from SGA.dbo.TipoDocOper
-- select top 10 * from SGA.dbo.Deudas where CondDeud = 2 and NumDI = 'f10102e'
-- select top 100 * from SGA.dbo.TipCargDeuda
-- select top 100 * from SGA.dbo.

SELECT top 10 * from SGA.dbo.Operacion WHERE NumDI = 'f10102e'
SELECT top 10 * from SGA.dbo.DetOper WHERE Comprobante like 'B%'
SELECT distinct TIPDOC_REF from SGA.dbo.DetOper
select top 10 * from SGA.dbo.Deudas


/*

-- Numeracion operacion Usuarios
DECLARE @NewNumOperChar CHAR(9);
SELECT @NewNumOperChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuario_Serie;

-- Numeracion boleta
DECLARE @NumBoletaChar char(4);
SELECT @NumBoletaChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuario_Serie AND SerieElec = @serie_Boleta;


/* OPERACION DE NUEVA DEUDA */
INSERT INTO SGA.dbo.Operacion
(
    SeriOper,NumOper,TipDI,NumDI,TipOper,
    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
)
VALUES
(
    @usuario_Serie, @NewNumOperChar, '12', @codigo_est, '01', -- condonacion
    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'CARGO DEL DERECHO DE CONDONACIÓN DE DEUDA',
    'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
    30, NULL, Null, NUll, NULL, NULL, NULL
);

/* DETALLE DE OPERACION DE NUEVA DEUDA */
INSERT INTO SGA.dbo.DetOper
(
    SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
    PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
    codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
)
VALUES
(
    @usuario_Serie, @NewNumOperChar, '001', '----', 'H', 100, '', @MatriculaAnioMax,
    @MatriculaPeriodoMax, @usuario_Serie+@NewDeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
    '----', '1', '7', '----', NULL, '3'
),
(
    @usuario_Serie, @NewNumOperChar, '002', '----', 'H', 4, '', @MatriculaAnioMax,
    @MatriculaPeriodoMax, @usuario_Serie+@NewDeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
    '----', '1', '7', '----', NULL, '3'
);


/* COMPROBANTE MAESTRA */
INSERT INTO SGA.dbo.Comprobantes_Mestra (
    idComprobanteElectronico, idComprobante, FechaEmision, TipoDocumento, Moneda, TipoOperacion,
    DocAnticipo, IdDocumento, Gravadas, Gratuitas, Inafectas, Exoneradas,
    DescuentoGlobal, TotalVenta, TotalIgv, TotalIsc, TotalOtrosTributos, MontoEnLetras,
    PlacaVehiculo, MontoPercepcion, MontoDetraccion, Estadosunat, CalculoIGV, CalculoISC,
    CalculoDetraccion, ETipoDocumento, ENroDocumento, ENombreLegal, ENombreComercial, EUbigeo,
    EDireccion, EUrbanizacion, RTipoDocumento, RNroDocumento, RNombreLegal, RNombreComercial,
    RUbigeo, RDireccion, RUrbanizacion, TipoDocumento_REL, NroDocumento_REL, NroReferencia_DIS,
    Tipo_DIS, Descripcion_DIS
)
VALUES (
    @serie_Boleta+@NumBoletaChar, @usuario_Serie+@NewDeudaNumeracion, CONVERT(DATETIME, GETDATE(), 120), '', 'PEN', '',
    '', '', '', '', '', '',
    '', '', '', '', '', '',
    '', '', '', '', '', '',
    '', '', '', '', '', '',
    '', '', '', '', '', '',
    '', '', '', '', '', '',
    '', ''
)

    /* DETALLE DE COMPROBANTE MAESTRA */
INSERT INTO SGA.dbo.DetalleComprobante_Maestra (
    idComprobanteElectronico, idComprobante, Id, Cantidad, UnidadMedida, CodigoItem,
    Descripcion, PrecioUnitario, PrecioReferencial, TipoPrecio, TipoImpuesto, Impuesto,
    ImpuestoSelectivo, OtroImpuesto, Descuento, TotalVenta, Suma
)
VALUES (
    @serie_Boleta+@NumBoletaChar, @DeudaSerie+@NewDeudaNumeracion, '', '', 'NIU', '01',
    '', 100, 0, '01', 10, 0,
    0, 0, 0, 104, 104
), (
    @serie_Boleta+@NumBoletaChar, @DeudaSerie+@NewDeudaNumeracion, '', '', 'NIU', '02',
    '', 4, 0, '01', 10, 0,
    0, 0, 0, 104, 104
)

*/

-- IF NOT EXISTS(SELECT * FROM SGA.dbo.Operacion WHERE Serie_FE+Numero_FE = TRIM(@ComprobanteFE) AND SeriOper = TRIM(@OperacionSerie)  AND NumOper = TRIM(@OperacionNumeracion) ) BEGIN
-- IF EXISTS(SELECT * FROM SGA.dbo.Operacion WHERE SeriOper = TRIM(@OperacionSerie)  AND NumOper = TRIM(@OperacionNumeracion) ) BEGIN
-- END 
-- ELSE BEGIN
-- END



