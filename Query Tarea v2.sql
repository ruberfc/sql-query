-- INICIO

-- Var total notas curso
DECLARE @TotalNotasCurso int;
-- Var Total cursos matriculados
DECLARE @TotalCursosMatriculados int;

DECLARE @Num_DI varchar(15) = 'A621524';
DECLARE @usuario_serie char(4) = '8888';
DECLARE @Serie_Boleta char(4) = 'B026';

-- Var Obtener ultimo año de matricula del estudiante Mtr_Anio
DECLARE @MatriculaAnioMax VARCHAR(4);
SELECT @MatriculaAnioMax = MAX(Mtr_Anio)from DBCampusNet.dbo.Nta_Nota where Est_Id = @Num_DI;

-- Var Obtener ultimo periodo de matricula del estudiante Mtr_Periodo
DECLARE @MatriculaPeriodoMax VARCHAR(4);
SELECT @MatriculaPeriodoMax = MAX(Mtr_Periodo) from DBCampusNet.dbo.Nta_Nota WHERE Est_Id = @Num_DI and Mtr_Anio =  @MatriculaAnioMax;

SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
FROM DBCampusNet.dbo.Nta_Nota
WHERE Mtr_Anio = @MatriculaAnioMax  and --(Mtr_Anio BETWEEN '2015' AND '2022') AND -- Mtr_Anio = '2015' and
    Mtr_Periodo = @MatriculaPeriodoMax and  -- Mtr_Periodo = 1 and -- Omitir
    Nta_Promedio = 'im' AND
    --Nta_Seccion in ('I', 'E', 'S') and 
    Est_Id = @Num_DI;

IF @TotalNotasCurso = 0 AND @TotalCursosMatriculados = 0 BEGIN
    print 'No existe registro alguno';
END 
ELSE BEGIN
    IF @TotalNotasCurso = @TotalCursosMatriculados BEGIN

        /* Impedidios todos los cursos que no pagaron sus cuotas */

        -- Var obtener ultimo periodo academico de la deuda de estudiante 
        DECLARE @DeudaPeriodoMax VARCHAR(4);
        SELECT @DeudaPeriodoMax = MAX(PeriAcad) from  SGA.dbo.Deudas WHERE NumDI = @Num_DI and [AñoAcad] =  @MatriculaAnioMax;

        IF EXISTS ( SELECT * 
            FROM SGA.dbo.Deudas deu
            WHERE 
                deu.[AñoAcad] = @MatriculaAnioMax AND
                deu.PeriAcad = @DeudaPeriodoMax AND
                -- (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
                deu.CondDeud IN (0,9) AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.NumDI = @Num_DI ) 
        BEGIN

            -- Declarar variables para almacenar los datos de cada registro
            DECLARE @Serie_Deu char(4), @Num_Deu char(8), @CondDeud_Deu char(1), @CodContab_Deu char(14), @Importe_Deu numeric(15,2), @TasaMora_Deu numeric(11,8), @NumCuota_Deu char(2);

            -- Declarar un cursor para recorrer los registros de deuda por usurio
            DECLARE cur_deudas_estudiante CURSOR FOR
            SELECT SeriDeud, NumDeud, CondDeud, CodContab, Importe, TasaMora, NumCuota
            FROM SGA.dbo.Deudas deu
            WHERE 
                deu.[AñoAcad] = @MatriculaAnioMax AND
                deu.PeriAcad = @DeudaPeriodoMax AND
                deu.CondDeud IN (0,9) AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.NumDI = @Num_DI;

            -- Abrir el cursor
            OPEN cur_deudas_estudiante; 

            -- Recorrer los registros uno por uno
            FETCH NEXT FROM cur_deudas_estudiante INTO @Serie_Deu, @Num_Deu, @CondDeud_Deu, @CodContab_Deu, @Importe_Deu, @TasaMora_Deu, @NumCuota_Deu;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Realizar las tareas aca
                
                -- Var incremento numeracion_operacion
                DECLARE @numMaxOper INT;
                SELECT @numMaxOper = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
                SET @numMaxOper = @numMaxOper + 1;

                -- Var conversion a char numeracion_operacion
                DECLARE @numMaxOperChar CHAR(9);
                SET @numMaxOperChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxOper ))), 9);

                -- Var Codigo especialidad_estudiante
                DECLARE @codEspEst VARCHAR(4);
                SELECT top 1 @codEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

                -- Var Sede estudio
                DECLARE @sedeEst VARCHAR(2);
                SELECT @sedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

                -- Var Facultad_id en Opercarion campo Programa
                DECLARE @programa char(2);
                SELECT TOP 1 @programa = car.Fac_Id FROM SGA.dbo.Car_Carrera car
                INNER JOIN SGA.dbo.Operacion o on car.Fac_Id = o.programa
                WHERE o.NumDI = @Num_DI;

                -- Var incremento numeracion_boleta
                DECLARE @numMaxBoleta INT;
                SELECT @numMaxBoleta = CONVERT(INT, NumBoleta) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
                SET @numMaxBoleta = @numMaxBoleta + 1;

                -- Var conversion a char numeracion_boleta
                DECLARE @numMaxBoletaChar CHAR(9);
                SET @numMaxBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxBoleta ))), 9);



                INSERT INTO SGA.dbo.Operacion
                (
                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                )
                VALUES
                (
                    @usuario_serie, @numMaxOperChar, '12', @Num_DI, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - Condonacion deuda 2015-I a 2022-II',
                    'ADMINISTRADOR', '01', @codEspEst, @sedeEst, @programa, '0',
                    NUll, @Serie_Boleta, @numMaxBoletaChar, NULL, NULL, NULL, NULL 
                );

                -- Var maximo año academico que no pago las cuotas
                DECLARE @maxAnioNoPagoCuotas CHAR(4);
                SELECT @maxAnioNoPagoCuotas = MAX(AñoAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') ;

                -- Var maximo periodo academico que no pago las cuotas
                DECLARE @maxPeriAcadDeuda CHAR(4);
                SELECT @maxPeriAcadDeuda = MAX(PeriAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') AND [AñoAcad] = @maxAnioNoPagoCuotas;

                INSERT INTO SGA.dbo.DetOper
                (
                SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF)
                VALUES
                    (
                        @usuario_serie, @numMaxOperChar, '001', '', 'D', 100, @NumCuota_Deu, @maxAnioNoPagoCuotas,
                        @maxPeriAcadDeuda, @Serie_Deu+@Num_Deu, '', '', '', '', '', '',
                        '', '', '', '', ''
                ),
                    (
                        @usuario_serie, @numMaxOperChar, '002', '', 'D', 4, @NumCuota_Deu, @maxAnioNoPagoCuotas,
                        @maxPeriAcadDeuda, @Serie_Deu+@Num_Deu, '', '', '', '', '', '',
                        '', '', '', '', ''
                );

                /*
                    INSERT INTO SGA.dbo.NumeracionFE (SerieElec, NumeroElec, c_tipdoc, serie, dif)
                    VALUES(@Serie_Boleta, @numMaxBoletaChar, '06', @usuario_serie, '3');
                */

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
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', '', '', '', '', '',
                    '', ''
                )

                INSERT INTO SGA.dbo.DetalleComprobante_Maestra (
                    idComprobanteElectronico, idComprobante, Id, Cantidad, UnidadMedida, CodigoItem,
                    Descripcion, PrecioUnitario, PrecioReferencial, TipoPrecio, TipoImpuesto, Impuesto,
                    ImpuestoSelectivo, OtroImpuesto, Descuento, TotalVenta, Suma
                )
                VALUES (
                    @Serie_Boleta+@numMaxBoletaChar, @usuario_serie+@numMaxOperChar, '', '', 'NIU', '01',
                    '', 100, 0, '01', 10, 0,
                    0, 0, 0, 104, 104
                ), (
                    @Serie_Boleta+@numMaxBoletaChar, @usuario_serie+@numMaxOperChar, '', '', 'NIU', '02',
                    '', 4, 0, '01', 10, 0,
                    0, 0, 0, 104, 104
                )

                SELECT top 10 * from sga.dbo.DetOper

                SELECT * from DetalleComprobante_Maestra where idComprobanteElectronico = 'B00100071769' and idComprobante = '0013000465588'

                select * from SGA.dbo.NumeracionFE where SerieElec = 'B001' and NumeroElec = '00071769'

                SELECT distinct itemtransf from sga.dbo.DetOper
                SELECT distinct  cantidad from sga.dbo.DetOper
                SELECT distinct  codint from sga.dbo.DetOper
                SELECT distinct  CondItem from sga.dbo.DetOper
                SELECT distinct  TipoComp from sga.dbo.DetOper

                -- Obtener el siguiente registro
                FETCH NEXT FROM cur_deudas_estudiante INTO @Serie_Deu, @Num_Deu, @CondDeud_Deu, @CodContab_Deu, @Importe_Deu, @TasaMora_Deu, @NumCuota_Deu; 
            END;

            -- Cerrar y liberar el cursor
            CLOSE cur_deudas_estudiante;
            DEALLOCATE cur_deudas_estudiante;

            -- Var incremento numeracion_operacion
            DECLARE @numMaxOper INT;
            SELECT @numMaxOper = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
            SET @numMaxOper = @numMaxOper + 1;

            -- Var conversion a char numeracion_operacion
            DECLARE @numMaxOperChar CHAR(9);
            SET @numMaxOperChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxOper ))), 9);

            -- Var Codigo especialidad estudiante
            DECLARE @codEspEst VARCHAR(4);
            SELECT top 1 @codEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

            -- Var Sede estudio
            DECLARE @sedeEst VARCHAR(2);
            SELECT @sedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

            -- Var Facultad_id en Opercarion campo Programa
            DECLARE @programa char(2);
            SELECT TOP 1 @programa = car.Fac_Id FROM SGA.dbo.Car_Carrera car
            INNER JOIN SGA.dbo.Operacion o on car.Fac_Id = o.programa
            WHERE o.NumDI = @Num_DI;

            -- Var incremento numeracion_boleta
            DECLARE @numMaxBoleta INT;
            SELECT @numMaxBoleta = CONVERT(INT, NumBoleta) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
            SET @numMaxBoleta = @numMaxBoleta + 1;

            -- Var conversion a char numeracion_boleta
            DECLARE @numMaxBoletaChar CHAR(9);
            SET @numMaxBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxBoleta ))), 9); 

            -- Var maximo año academico que no pago las cuotas
            DECLARE @maxAnioNoPagoCuotas CHAR(4);
            SELECT @maxAnioNoPagoCuotas = MAX(AñoAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') ;

            -- Var maximo periodo academico que no pago las cuotas
            DECLARE @maxPeriAcadDeuda CHAR(4);
            SELECT @maxPeriAcadDeuda = MAX(PeriAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') AND [AñoAcad] = @maxAnioNoPagoCuotas;

            -- Var maximope
            INSERT INTO SGA.dbo.Operacion
                (
                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                )
                VALUES
                (
                        @usuario_serie, @numMaxOperChar, '12', @Num_DI, '01', -- condonacion
                        CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - Condonacion deuda 2015-I a 2022-II',
                        'ADMINISTRADOR', '01', @codEspEst, @sedeEst, @programa, '0',
                        NUll, @Serie_Boleta, @numMaxBoletaChar, NULL, NULL, NULL, NULL 
                );

            INSERT INTO SGA.dbo.DetOper
                (
                SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF)
            VALUES
                (
                    @usuario_serie, @numMaxOperChar, '001', '', 'D', 100, '', @maxAnioNoPagoCuotas,
                    @maxPeriAcadDeuda, '', '', '', '', '', '', '',
                    '', '', '', '', ''
            ),
                (
                    @usuario_serie, @numMaxOperChar, '002', '', 'D', 4, '', @maxAnioNoPagoCuotas,
                    @maxPeriAcadDeuda, '', '', '', '', '', '', '',
                    '', '', '', '', ''
            );

            INSERT INTO SGA.dbo.NumeracionFE (SerieElec, NumeroElec, c_tipdoc, serie, dif)
            VALUES(@Serie_Boleta, @numMaxBoletaChar, '06', @usuario_serie, '3');


            UPDATE SGA.dbo.Usuarios SET NumOper = @numMaxOperChar, NumBoleta = @numMaxBoletaChar WHERE Serie = @usuario_serie;

            -- Declarar variables para almacenar los datos de cada registro
            DECLARE @Serie_Deu_Actual char(4), @Num_Deu_Actual char(8);

            -- Declarar un cursor para recorrer los registros de deuda por usurio
            DECLARE registros_cursor_deudas CURSOR FOR
            SELECT SeriDeud, NumDeud
            FROM SGA.dbo.Deudas deu
            WHERE deu.CondDeud IN (0,9) AND
                (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.NumDI = @Num_DI;

            -- Abrir el cursor
            OPEN registros_cursor;

            -- Recorrer los registros uno por uno
            FETCH NEXT FROM registros_cursor_deudas INTO @Serie_Deu_Actual, @Num_Deu_Actual;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Realizar las operaciones deseadas con los datos del registro
                UPDATE SGA.dbo.Deudas SET CondDeud = '2', DocCanc = @usuario_serie+@numMaxOperChar  WHERE SeriDeud = @Serie_Deu_Actual AND NumDeud = @Num_Deu_Actual;

                select top 10 * from SGA.dbo.Deudas where NumDI = 'f10102e'
                select top 10 * from SGA.dbo.DetOper do
                inner join SGA.dbo.Deudas deu on  do.DocRef = deu.SeriDeud + ' ' + deu.NumDeud or do.DocRef = deu.SeriDeud+deu.NumDeud
                where DocRef <> ''

                select top 10 * from SGA.dbo.DetOper  where DocRef = '000 01102024'
                select top 10 * from SGA.dbo.DetOper  where DocRef like '0000%'
                select top 10 * from SGA.dbo.DetOper  where DocRef <> ''

                SELECT top 10 * from SGA.dbo.Deudas where SeriDeud = '000' AND NumDeud = '01102024'

                -- Obtener el siguiente registro
                FETCH NEXT FROM registros_cursor_deudas INTO @Serie_Deu_Actual, @Num_Deu_Actual 
            END;

            -- Cerrar y liberar el cursor
            CLOSE registros_cursor_deudas;
            DEALLOCATE registros_cursor_deudas;


        END 
        ELSE BEGIN
            /* Impedidios todos los cursos que pagaron sus cuotas */

            -- Var maximo año academico que pago las cuotas
            DECLARE @maxAnioPagoCuotas CHAR(4);
            SELECT @maxAnioPagoCuotas = MAX(AñoAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  = '1';

            -- Declarar variables para almacenar los datos de cada registro Operaciones de pagos 
            DECLARE @Serie_Oper_Actual char(4), @Num_Oper_Actual char(8), @Declarado_Sunat bit, @Total_Operacion numeric(11,2), @Item_DetOper CHAR(3);

            -- Declarar un cursor para recorrer los registros de operacion por estudiante en el maximo año academico
            DECLARE reg_cursor_DetOper CURSOR FOR
            SELECT o.SeriOper, o.NumOper, o.Declarado_Sunat, o.TotOper, do.item
            FROM SGA.dbo.Operacion o
                INNER JOIN SGA.dbo.DetOper do on o.SeriOper = do.SeriOper AND o.NumOper = do.NumOper
            WHERE 
                do.[AñoAcad] = @maxAnioPagoCuotas AND
                o.NumDI = @Num_DI AND
                do.NumCuota in ('01', '02', '03', '04', '05');

            -- Abrir el cursor
            OPEN reg_cursor_DetOper
            -- Recorrer los registros uno por uno
            FETCH NEXT FROM reg_cursor_DetOper INTO @Serie_Oper_Actual, @Num_Oper_Actual, @Declarado_Sunat, @Total_Operacion, @Item_DetOper
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Realizar las operaciones deseadas con los datos del registro

                -- Var incremento numeracion_NCredito
                DECLARE @numMaxCredito int;
                SELECT @numMaxCredito = CONVERT(INT, NumNCredito) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
                SET @numMaxCredito = @numMaxCredito + 1;

                -- Var conversion a char numeracion_NCredito
                DECLARE @numMaxCreditoChar CHAR(9);
                SET @numMaxCreditoChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxCredito ))), 9);

                
                IF @Declarado_Sunat = 1 BEGIN

                    INSERT INTO SGA.dbo.Notas_Cred_Deb
                        (
                            SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
                            Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
                        )
                    VALUES
                        (
                            @usuario_serie, @Num_Oper_Actual, CONVERT(date, GETDATE(), 120), 'BB26', @numMaxCreditoChar, 'Condonacion deuda',
                            @Total_Operacion, 'NC', '01', @Item_DetOper, @Serie_Oper_Actual, @Num_Oper_Actual
                        );

                    UPDATE SGA.dbo.Usuarios SET NumNCredito = @numMaxCreditoChar where Serie = @usuario_serie 
                        
                    -- UPDATE SGA.dbo.Operacion SET TipOper = '02' WHERE SeriOper = @Serie_Oper_Actual AND NumOper = @Num_Oper_Actual    


                END 
                ELSE BEGIN
                    -- UPDATE SGA.dbo.Usuarios SET NumNCredito = @numMaxCreditoChar where Serie = @usuario_serie
                    UPDATE SGA.dbo.Operacion SET TipOper = '' WHERE SeriOper = @Serie_Oper_Actual AND NumOper = @Num_Oper_Actual
                END
            END

            -- Obtener el siguiente registro
            FETCH NEXT FROM reg_cursor_DetOper INTO @Serie_Deu_Actual, @Num_Deu_Actual, @Declarado_Sunat, @Total_Operacion, @Item_DetOper;

        END

        -- Cerrar y liberar el cursor
        CLOSE reg_cursor_DetOper;
        DEALLOCATE reg_cursor_DetOper;



    END
    ELSE BEGIN
        
        print 'algo fallo'
    END
END