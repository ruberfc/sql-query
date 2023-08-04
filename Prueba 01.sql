GO


CREATE OR ALTER PROCEDURE SP_PROCESO_CONDONACION(
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

                    -- IF EXISTS( SELECT TOP 1 * FROM SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = TRIM(@ComprobanteFE) ) BEGIN
                    -- END
                    -- ELSE BEGIN 
                    -- END


                    /* OPERACION CANCELAR DEUDA */
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
                        CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, @DeudaImporte, '1', 1, 'OPERACION DE CANCELACION DEUDA '+@DeudaSerie+@DeudaNumeracion,
                        'ADMINISTRADOR', '----', @CodEspEst, @SedeEst, @Programa, '0',
                        30, @serie_NotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
                    );


                   DECLARE @DetOperSerie CHAR(4), @DetOperNum CHAR(9), @DetOperItem CHAR(3), @DetOperCodContab CHAR(14),  @DetOperImporte NUMERIC(15,2);

                    DECLARE C_DETALLE_OPERACION  CURSOR FOR   
                        SELECT item CodContab, Importe
                        FROM SGA.dbo.DetOper 
                        WHERE Comprobante = TRIM(@ComprobanteFE);
                                -- DocRef = TRIM(@DeudaSerie)+TRIM(@DeudaNumeracion) or 
                    OPEN C_DETALLE_OPERACION;

                    FETCH NEXT FROM C_DETALLE_OPERACION INTO @DetOperSerie, @DetOperNum, @DetOperItem, @DetOperCodContab, @DetOperImporte;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN

                        /* DETALLE OPERACION CANCELAR DEUDA */
                        INSERT INTO SGA.dbo.DetOper
                        (
                            SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                            PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                            codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                        )
                        VALUES
                        (
                            @usuario_Serie, @NumOperChar, @DetOperItem, '6595257', 'D', @DetOperImporte, @DeudaNumCuota, @MatriculaAnioMax,
                            @MatriculaPeriodoMax, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                            '----', '1', '7', @serie_NotaCredito+@NumNotaCreditoChar, @ComprobanteFE, '3'
                        );

                        FETCH NEXT FROM C_DETALLE_OPERACION INTO @DetOperItem, @DetOperCodContab, @DetOperImporte;
                    END
                    CLOSE C_DETALLE_OPERACION;
                    DEALLOCATE C_DETALLE_OPERACION;


                    /* Cursor detalle comprobante */
                    -- DECLARE @DeudaSerie CHAR(4), @DeudaNumeracion CHAR(8), @DeudaCodContab char(14), @DeudaImporte NUMERIC(15,2), @DeudaNumCuota CHAR(2);
                    -- select distinct CodigoItem from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200919841'
                    -- select top 10 * from SGA.dbo.DetalleComprobante_Maestra

                    /*
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
                    */


                    /*
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
                    */


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


                    /*
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
                    */


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

select top 10 * from deudas


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

select * from SGA.dbo.PensionesxCobrar WHERE Comprobante = 'E00100000009'
select * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '02425526'
select * from SGA.dbo.DetOper WHERE SeriOper = '8888' and NumOper = '000025151'


-- Get the space used by table TableName
SELECT TABL.name AS table_name,
INDX.name AS index_name,
SUM(PART.rows) AS rows_count,
SUM(ALOC.total_pages) AS total_pages,
SUM(ALOC.used_pages) AS used_pages,
SUM(ALOC.data_pages) AS data_pages,
(SUM(ALOC.total_pages)*8/1024) AS total_space_MB,
(SUM(ALOC.used_pages)*8/1024) AS used_space_MB,
(SUM(ALOC.data_pages)*8/1024) AS data_space_MB
FROM sys.tables AS TABL
INNER JOIN sys.indexes AS INDX
ON TABL.object_id = INDX.object_id
INNER JOIN sys.partitions AS PART
ON INDX.object_id = PART.object_id
AND INDX.index_id = PART.index_id
INNER JOIN sys.allocation_units AS ALOC
ON PART.partition_id = ALOC.container_id
WHERE TABL.name LIKE '%TableName%'
AND INDX.object_id > 255
AND INDX.index_id <= 1
GROUP BY TABL.name, 
INDX.object_id,
INDX.index_id,
INDX.name
ORDER BY Object_Name(INDX.object_id),
(SUM(ALOC.total_pages)*8/1024) DESC
GO

select top 10 * from SGA.dbo.PensionesxCobrar where Comprobante = '2020087359'


select top 10 * from SGA.dbo.DetOper where Comprobante = '2020087359' -- 0001 000225902


select top 10 * from SGA.dbo.Operacion where SeriOper = '0001' and NumOper = '000225902'
select top 10 * from SGA.dbo.DetOper where SeriOper = '0001' and NumOper = '000225902'

/* J03932K */

SELECT top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000920026'
SELECT top 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000920026'

/* f10102e */
SELECT top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '001075903'
SELECT top 10 * from SGA.dbo.DetOper where SeriOper = '0002' and NumOper = '001075903'


SELECT top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '001075903'
SELECT top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000920026'

SELECT top 10 * from SGA.dbo.DetOper where SeriOper = '0002' and NumOper = '001075903'
SELECT top 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000920026'


DECLARE @TablaResultado TABLE (
    comprobante varchar(15),
    cantidad bigint
);



insert into @TablaResultado (comprobante, cantidad)

SELECT pc.Comprobante AS id_principal, COUNT(deu.NumDeud) AS cantidad_referencias
FROM SGA.dbo.PensionesxCobrar pc
LEFT JOIN SGa.dbo.Deudas deu ON pc.SeriDeud = deu.SeriDeud AND pc.NumDeud = deu.NumDeud
--WHERE tp.Comprobante like 'B%'
where deu.CondDeud in ('0', '9')
GROUP BY pc.Comprobante
HAVING COUNT(deu.NumDeud) > 1;

/* */

DECLARE @RComprobante VARCHAR(15), @RCantidad BIGINT;

DECLARE C_TABLA_RESUL CURSOR FOR
SELECT pc.Comprobante AS id_principal, COUNT(deu.NumDeud) AS cantidad_referencias
FROM SGA.dbo.PensionesxCobrar pc
LEFT JOIN SGa.dbo.Deudas deu ON pc.SeriDeud = deu.SeriDeud AND pc.NumDeud = deu.NumDeud
--WHERE tp.Comprobante like 'B%'
    where deu.CondDeud in ('0', '9')
    GROUP BY pc.Comprobante
    HAVING COUNT(deu.NumDeud) > 1;

OPEN C_TABLA_RESUL;
    
FETCH NEXT FROM C_TABLA_RESUL INTO @RComprobante, @RCantidad
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (select * from SGA.dbo.Operacion where NumComFisico = @RComprobante ) BEGIN
        PRINT 'Existe el comprobante : '+@RComprobante
    END
    ELSE BEGIN
        PRINT 'No existe el comprobante: '+@RComprobante
    END


    FETCH NEXT FROM C_TABLA_RESUL INTO @RComprobante, @RCantidad
END
CLOSE C_TABLA_RESUL;
DEALLOCATE C_TABLA_RESUL;



if exists (
    SELECT * from SGA.dbo.DetOper do 
    INNER join @TablaResultado  tr on do.Comprobante = tr.comprobante
)

-- select top 10 * from SGA.dbo.DetOper


select comprobante as 'Comprobante Resultado', cantidad as 'Cantidad Resultado' from @TablaResultado

/* CON WHILE */

DECLARE @rows INT;
DECLARE @rowid INT;
DECLARE @SeriDeud CHAR(4), @NumDeud CHAR(8), @CodContab CHAR(14), @Importe NUMERIC(15,2), @TasaMora NUMERIC(11,8), @NumCuota CHAR(2); 
declare @DeudaTemp table (
    rowid int identity(1,1), 
    SeriDeud char(4),
    NumDeud char(8),
    CodContab char(14),
    Importe numeric(15, 2),
    TasaMora numeric(11, 8),
    NumCuota char(2)
);


INSERT INTO @DeudaTemp (SeriDeud, NumDeud, CodContab, Importe, TasaMora, NumCuota)
SELECT  -- top 10 *
    SeriDeud, NumDeud, CodContab, Importe, TasaMora, NumCuota
    FROM SGA.dbo.Deudas
        WHERE   AñoAcad = '2015' AND
                PeriAcad = '02' AND
                NumCuota in ('01', '02', '03', '04', '05') AND  --@DeudaNumCuota AND 
                CondDeud in (0, 9) and
                NumDI = 'A621524';


SELECT @rows = count(rowid) from @DeudaTemp
WHILE (@rows > 0)
BEGIN
    SELECT top 1 @rowid = rowid, @SeriDeud = SeriDeud, @NumDeud = NumDeud, @CodContab = CodContab, @Importe = Importe, @TasaMora = TasaMora , @NumCuota = NumCuota
    FROM @DeudaTemp

    IF EXISTS(SELECT * from SGA.dbo.PensionesxCobrar where SeriDeud = TRIM(@SeriDeud) and NumDeud = TRIM(@NumDeud) and Comprobante LIKE 'B%' or Comprobante LIKE 'F%') BEGIN
        
        -- Comprobante FE PensionesxCobrar
        DECLARE @ComprobanteFE varchar(15);
        SELECT @ComprobanteFE = Comprobante FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@SeriDeud) AND NumDeud = TRIM(@NumDeud);
       
        DECLARE @rowsDet INT;
        DECLARE @rowidDet INT;
        DECLARE @DetSeri CHAR(4), @DetNum CHAR(8), @DetItem CHAR(3), @DetCodContab CHAR(14), @DetImporte NUMERIC(15,2), @DetNumCuota CHAR(2), @DetDocRef char(12), @DetComprobante CHAR(12); 
        DECLARE @DeTalleOperTemp table (
            rowidDet int identity(1,1), 
            SeriOper char(4),
            NumOper char(9),
            item char(3),
            CodContab char(14),
            Importe numeric(15, 2),
            NumCuota char(2),
            DocRef char(12),
            Comprobante char(12)
        );

        INSERT INTO @DeTalleOperTemp ( SeriOper, NumOper, item, CodContab, Importe, NumCuota, DocRef, Comprobante)
        SELECT  SeriOper, NumOper, item, CodContab, Importe, NumCuota, DocRef, Comprobante FROM SGA.dbo.DetOper 
        WHERE Comprobante = @ComprobanteFE


        SELECT @rowsDet = count(@rowidDet) from @DeTalleOperTemp

        WHILE (@rows > 0)
        BEGIN
            SELECT top 1 @rowidDet = rowidDet, @DetSeri = SeriOper, @DetNum = NumOper, @DetItem = item, @DetCodContab = CodContab, @DetImporte = Importe, @DetNumCuota = NumCuota, @DetDocRef = DocRef, @DetComprobante = Comprobante
            FROM @DeTalleOperTemp
            

            DELETE from @DeTalleOperTemp where rowidDet = @rowidDet
            SELECT @rowsDet = count(rowidDet) from @DeTalleOperTemp
        END

        

        -- select top 10 * from SGA.dbo.DetOper where Comprobante = '1110086668' --- 0002 000466049

        -- select top 10 * from SGA.dbo.Operacion where NumComFisico = '1110086668' --- 0002 000466049
        -- select top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '000466049'

    END
    ELSE BEGIN

        -- Comprobante Fisico
        DECLARE @ComprobanteFisico varchar(15);
        SELECT @ComprobanteFE = Comprobante FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@SeriDeud) AND NumDeud = TRIM(@NumDeud);


    END


    DELETE from @DeudaTemp where rowid = @rowid
    SELECT @rows = count(rowid) from @DeudaTemp
END


