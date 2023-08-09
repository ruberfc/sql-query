GO
CREATE OR ALTER PROCEDURE SP_PROCESO_CONDONACION_TRANSACION(
    @codigo_est varchar(15)
)AS
BEGIN
    BEGIN TRY

        BEGIN TRANSACTION;

            DECLARE @usuario_Serie CHAR(4) = '8888';
            DECLARE @serie_Recibo CHAR(4) = 'R026';
            DECLARE @serie_Boleta CHAR(4) = 'B026';
            DECLARE @serie_NotaCredito CHAR(4) = 'BA26';

            -- Total notas curso y total cursos matriculados
            DECLARE @TotalNotasCurso BIGINT, @TotalCursosMatriculados BIGINT;

            
            -- Obtener ultimo año de matricula del estudiante Nta_Nota
            DECLARE @MatriculaAnioMax VARCHAR(4);
            SELECT @MatriculaAnioMax = MAX(Mtr_Anio) from DBCampusNet.dbo.Nta_Nota where Est_Id = @codigo_est;


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

                    -- Numeracion operacion
                    DECLARE @NumOperChar CHAR(9);
                    SELECT @NumOperChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuario_Serie;

                    -- Especialidad, sede y programa
                    DECLARE @CodEsp VARCHAR(4), @SedeEst VARCHAR(2), @Programa CHAR(2);
                    SELECT top 1 @CodEsp = CodEspe, @SedeEst = sed_id, @Programa = MAC_id  FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;


                    DECLARE @rows INT;
                    DECLARE @rowid INT;
                    DECLARE @DeudaSeri CHAR(4), @DeudaNum CHAR(8), @DeudaCodContab CHAR(14), @DeudaImporte NUMERIC(15,2), @DeudaTasaMora NUMERIC(11,8), @DeudaNumCuota CHAR(2); 
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
                    SELECT SeriDeud, NumDeud, CodContab, Importe, TasaMora, NumCuota
                    FROM SGA.dbo.Deudas
                    WHERE   AñoAcad = @MatriculaAnioMax AND
                            PeriAcad = @MatriculaPeriodoMax AND
                            NumCuota in ('01', '02', '03', '04', '05') AND
                            CondDeud in (0, 9) and
                            NumDI = @codigo_est;


                    SELECT @rows = count(rowid) from @DeudaTemp;
                    WHILE (@rows > 0)
                    BEGIN

                        SELECT top 1 @rowid = rowid, @DeudaSeri = SeriDeud, @DeudaNum = NumDeud, @DeudaCodContab = CodContab, @DeudaImporte = Importe, @DeudaTasaMora = TasaMora , @DeudaNumCuota = NumCuota
                        FROM @DeudaTemp;

                        IF EXISTS(SELECT * from SGA.dbo.PensionesxCobrar where SeriDeud = TRIM(@DeudaSeri) and NumDeud = TRIM(@DeudaNum) and Comprobante LIKE 'B%' or Comprobante LIKE 'F%') BEGIN
                            /* ELECTRONICO */

                            -- Comprobante FE
                            DECLARE @ComprobanteFE varchar(15);
                            SELECT @ComprobanteFE = Comprobante FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@DeudaSeri) AND NumDeud = TRIM(@DeudaNum);

                            -- Numeracion nota credito
                            DECLARE @NumNotaCreditoChar char(8);
                            SELECT @NumNotaCreditoChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuario_Serie AND SerieElec = @serie_NotaCredito;


                            -- SeriOper, NumOper, TotOper, Cod_AfectaIGV
                            DECLARE @OperSeriOper char(4), @OperNumOper CHAR(9), @OperTotOper NUMERIC(11, 2), @OperCod_AfectaIGV INT;
                            SELECT @OperSeriOper = SeriOper, @OperNumOper = NumOper, @OperTotOper = TotOper, @OperCod_AfectaIGV = Cod_AfectaIGV FROM SGA.dbo.Operacion WHERE TRIM(Serie_FE)+TRIM(Numero_FE) = TRIM(@ComprobanteFE);


                            IF EXISTS (select * from SGA.dbo.Descuento_doble where Seriedeud = TRIM(@DeudaSeri)+TRIM(@DeudaNum) AND Numdi = @codigo_est) BEGIN
                                /* DESCUENTO DOBLE */

                                -- Operacion
                                INSERT INTO SGA.dbo.Operacion
                                (
                                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                                )VALUES
                                (
                                    @usuario_Serie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, -@OperTotOper, '1', 1, 'OPERACION DE CANCELACION DEUDA '+ TRIM(@DeudaSeri)+TRIM(@DeudaNum),
                                    'ADMINISTRADOR', '----', @CodEsp, @SedeEst, @Programa, '0',
                                    30, @serie_NotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
                                );

                                -- Detalle
                                INSERT INTO SGA.dbo.DetOper
                                (
                                    SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                                    PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                                    codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                                )
                                VALUES
                                (
                                    @usuario_Serie, @NumOperChar, '001', '6595257', 'D', -@OperTotOper, @DeudaNumCuota, @MatriculaAnioMax,
                                    @MatriculaPeriodoMax, TRIM(@DeudaSeri)+TRIM(@DeudaNum), 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), '', 1,
                                    '----', '----', '7', @serie_NotaCredito+@NumNotaCreditoChar, @ComprobanteFE, '3'
                                );


                                -- Nota Credito
                                INSERT INTO SGA.dbo.Notas_Cred_Deb
                                (
                                    SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
                                    Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
                                )
                                VALUES
                                (
                                    @usuario_Serie, @NumOperChar, CONVERT(date, GETDATE(), 120), @serie_NotaCredito, @NumNotaCreditoChar, 'COMPROBANTE AFECTADO '+@ComprobanteFE,
                                    @OperTotOper, 'NC', '01', '01', @OperSeriOper, @OperNumOper
                                );

                                UPDATE SGA.dbo.NumeracionFE SET 
                                    NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @NumNotaCreditoChar) + 1 ))), 8)
                                WHERE serie = @usuario_Serie AND SerieElec = @serie_NotaCredito;

                                UPDATE SGA.dbo.Usuarios Set 
                                    NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  
                                Where Serie = @usuario_Serie;

                            END
                            ELSE BEGIN

                                DECLARE @rowsDet INT;
                                DECLARE @rowidDet INT;
                                DECLARE @DetSeri CHAR(4), @DetNum CHAR(8), @DetItem CHAR(3), @DetCodContab CHAR(14), @DetTipCodCont CHAR(1), @DetImporte NUMERIC(15,2), @DetNumCuota CHAR(2), @DetDocRef char(12), @DetComprobante CHAR(12); 
                                DECLARE @DeTalleOperTemp table (
                                    rowidDet int identity(1,1), 
                                    SeriOper char(4),
                                    NumOper char(9),
                                    item char(3),
                                    CodContab char(14),
                                    TipCodCont char(1),
                                    Importe numeric(15, 2),
                                    NumCuota char(2),
                                    DocRef char(12),
                                    Comprobante char(12)
                                );
                                INSERT INTO @DeTalleOperTemp ( SeriOper, NumOper, item, CodContab, TipCodCont, Importe, NumCuota, DocRef, Comprobante)
                                SELECT  SeriOper, NumOper, item, CodContab, TipCodCont, Importe, NumCuota, DocRef, Comprobante FROM SGA.dbo.DetOper 
                                WHERE Comprobante = @ComprobanteFE;

                                -- Operacion
                                INSERT INTO SGA.dbo.Operacion
                                (
                                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                                )VALUES
                                (
                                    @usuario_Serie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, -@OperTotOper, '1', 1, 'OPERACION DE CANCELACION DEUDA '+TRIM(@DeudaSeri)+TRIM(@DeudaNum),
                                    'ADMINISTRADOR', '----', @CodEsp, @SedeEst, @Programa, '0',
                                    30, @serie_NotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
                                );

                                SELECT @rowsDet = count(@rowidDet) from @DeTalleOperTemp;
                                WHILE (@rows > 0)
                                BEGIN
                                    SELECT top 1 @rowidDet = rowidDet, @DetSeri = SeriOper, @DetNum = NumOper, @DetItem = item, @DetCodContab = CodContab, @DetImporte = Importe, @DetNumCuota = NumCuota, @DetDocRef = DocRef, @DetComprobante = Comprobante
                                    FROM @DeTalleOperTemp;

                                    -- Detalle
                                    INSERT INTO SGA.dbo.DetOper
                                    (
                                        SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                                        PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                                        codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                                    )
                                    VALUES
                                    (
                                        @usuario_Serie, @NumOperChar, @DetItem, '6595257', 'H', -@DetImporte, @DetNumCuota, @MatriculaAnioMax,
                                        @MatriculaPeriodoMax, @DetDocRef, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), '', 1,
                                        '----', '----', '7', @serie_NotaCredito+@NumNotaCreditoChar, @ComprobanteFE, '3'
                                    );
                                        
                                    DELETE from @DeTalleOperTemp where rowidDet = @rowidDet;
                                    SELECT @rowsDet = count(rowidDet) from @DeTalleOperTemp;
                                    
                                END 

        
                                -- Nota Credito
                                INSERT INTO SGA.dbo.Notas_Cred_Deb
                                (
                                    SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
                                    Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
                                )
                                VALUES
                                (
                                    @usuario_Serie, @NumOperChar, CONVERT(date, GETDATE(), 120), @serie_NotaCredito, @NumNotaCreditoChar, 'ANULACIÓN DE LA OPERACIÓN '+@ComprobanteFE,
                                    @OperTotOper, 'NC', '01', '01', @OperSeriOper, @OperNumOper
                                );


                                UPDATE SGA.dbo.NumeracionFE SET 
                                    NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @NumNotaCreditoChar) + 1 ))), 8)
                                WHERE serie = @usuario_Serie AND SerieElec = @serie_NotaCredito;

                                UPDATE SGA.dbo.Usuarios Set 
                                    NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  
                                Where Serie = @usuario_Serie;


                            END

                        END
                        ELSE BEGIN
                            /* FISICO */

                            -- Comprobante Fisico
                            DECLARE @ComprobanteFisico varchar(15);
                            SELECT @ComprobanteFisico = Comprobante FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@DeudaSeri) AND NumDeud = TRIM(@DeudaNum);

                            -- Recibo Numeracion
                            DECLARE @ReciboNum varchar(15);
                            SELECT @ReciboNum = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuario_Serie AND SerieElec = @serie_Recibo; 

                            -- Operacion
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
                                CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, -@DeudaImporte, '1', 1, 'OPERACIÓN DE CANCELACIÓN DE DEUDA ' + @DeudaSeri+@DeudaNum+  ' POR DERECHO DE CONDONACIÓN',
                                'ADMINISTRADOR', '----', @CodEsp, @SedeEst, @Programa, '0',
                                30, '', '', 'RC', NULL, NULL, NULL
                            );
                            

                            -- Detalle
                            INSERT INTO SGA.dbo.DetOper
                            (
                                SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                                PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                                codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                            )
                            VALUES
                            (
                                @usuario_Serie, @NumOperChar, '001', '6595257', 'D', @DeudaImporte, @DeudaNumCuota, @MatriculaAnioMax,
                                @MatriculaPeriodoMax, @DeudaSeri+@DeudaNum, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), '', 1,
                                '----', '----', '0', @serie_Recibo+@ReciboNum, @ComprobanteFisico, '0'
                            );

                            UPDATE SGA.dbo.NumeracionFE SET 
                                NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @ReciboNum) + 1 ))), 8)
                            WHERE serie = @usuario_Serie AND SerieElec = @serie_Recibo;

                            UPDATE SGA.dbo.Usuarios Set 
                                NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  
                            Where Serie = @usuario_Serie;                                           

                        END

                        Update SGA.dbo.Deudas SET 
                                CondDeud = '2', 
                                Observac = 'DERECHO DE CONDONACIÓN DE DEUDA - RESOLUCIÓN N° 0216-2023-CU-UPLA',  
                                DocCanc = @usuario_Serie+@NumOperChar, 
                                actualiza =  CONVERT(CHAR(1), CAST(ISNULL(actualiza, '0')  AS INT) + 1) 
                        WHERE  
                                SeriDeud = @DeudaSeri AND NumDeud = @DeudaNum
                                -- [AñoAcad] = @MatriculaAnioMax AND
                                -- PeriAcad = @MatriculaPeriodoMax AND
                                -- NumCuota = @DeudaNumCuota AND
                                -- CondDeud in (0,9) AND
                                -- NumDI = @codigo_est;
                        

                        DELETE from @DeudaTemp where rowid = @rowid;
                        SELECT @rows = count(rowid) from @DeudaTemp;
                    END


                    /* GENERAR NUEVA DEUDA */

                    -- Numeracion Deuda y Operacion
                    DECLARE @NewDeudaNumeracion CHAR(8), @NewOperacionNumeracion CHAR(9);
                    Select @NewDeudaNumeracion = NumDeud, @NewOperacionNumeracion = NumOper from SGA.dbo.Usuarios where Serie = @usuario_Serie;

                    -- Numeracion boleta
                    DECLARE @NewBoletaNumeracion CHAR(8);
                    Select @NewBoletaNumeracion = NumeroElec from SGA.dbo.NumeracionFE where Serie = @usuario_Serie and SerieElec = @serie_Boleta;

                    -- CREAR DEUDA
                    INSERT INTO SGA.dbo.Deudas 
                    (
                        SeriDeud, NumDeud, FecCarg, CondDeud, TipDI, NumDI,
                        CodContab, Importe, FecVenc, TasaMora, TipMoneda, TipCambio,
                        NumCuota, AñoAcad, PeriAcad, TipCarg, Observac, Usuario,
                        DocCanc, EscPen, TipDoc, cantidad, actualiza, CondDeclarado, Valor
                    )
                    VALUES 
                    (
                        @usuario_Serie, @NewDeudaNumeracion, CONVERT(smalldatetime, GETDATE(), 120), '0', '12', @CodEsp,
                        '----', 104, '2023-12-31 00:00:00', 0.0005, '1', 1,
                        '', @MatriculaAnioMax, @MatriculaPeriodoMax, '----', 'DEUDA POR DERECHO DE CONDONACIÓN DE DEUDA - RESOLUCIÓN N° 0216-2023-CU-UPLA.', 'ADMINISTRADOR',
                        '', NULL, NULL, NULL, NULL, 0, NULL
                    );

                    -- OPERACION DE DEUDA
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
                        'ADMINISTRADOR', '----', @CodEsp, @SedeEst, @Programa, '0',
                        30, NULL, NUll, NUll, NULL, NULL, NULL
                    );

                    -- DETALLE DE OPERACION DE DEUDA
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
                        '----', '1', '1', @serie_Boleta+@NewBoletaNumeracion, NULL, ''
                    ),
                    (
                        @usuario_Serie, @NewOperacionNumeracion, '002', '----', 'H', 4, '', @MatriculaAnioMax,
                        @MatriculaPeriodoMax, @usuario_Serie+@NewDeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                        '----', '1', '1', @serie_Boleta+@NewBoletaNumeracion, NULL, ''
                    );

                    UPDATE SGA.dbo.Usuarios SET 
                        NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NewOperacionNumeracion) + 1 ))), 9),
                        NumDeud = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NewDeudaNumeracion) + 1 ))), 9)
                    Where Serie = @usuario_Serie;

                    UPDATE SGA.dbo.NumeracionFE SET 
                        NumeroElec = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NewBoletaNumeracion) + 1 ))), 9)
                    Where Serie = @usuario_Serie AND SerieElec = @serie_Boleta; 

                    RETURN 'Deuda generada ' + @usuario_Serie + ' ' + @NewDeudaNumeracion

                END
                ELSE BEGIN
                    RETURN 'No se hiso impedir en todos los cursos';
                END

            END

        COMMIT;

    END TRY
    BEGIN CATCH
        -- En caso de error, revertir la transacción
        ROLLBACK;
        RETURN 'Ocurrió un error: ' + ERROR_MESSAGE();
    END CATCH

END;