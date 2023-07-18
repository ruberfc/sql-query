-- INICIO

-- Var total notas curso
DECLARE @totalNotasCurso int;
-- Var Total cursos matriculados
DECLARE @totalCursosMatriculados int;

DECLARE @Num_DI varchar(15) = 'A621524';
DECLARE @usuario_serie char(4) = '8888';

SELECT @totalNotasCurso = count(Nta_Promedio), @totalCursosMatriculados = count(Asi_Id)
FROM DBCampusNet.dbo.Nta_Nota
WHERE (Mtr_Anio BETWEEN '2015' AND '2022') AND -- Mtr_Anio = '2015' and
    --Mtr_Periodo = 1 and -- Omitir
    Nta_Promedio = 'im' AND
    --Nta_Seccion in ('I', 'E', 'S') and 
    Est_Id = @Num_DI;

IF @totalNotasCurso = 0 AND @totalCursosMatriculados = 0 BEGIN
    print 'No existe registro alguno';
END 
ELSE BEGIN
    IF @totalNotasCurso = @totalCursosMatriculados BEGIN

        IF EXISTS ( SELECT * 
            FROM SGA.dbo.Deudas deu
            WHERE 
                deu.CondDeud IN (0,9) AND
                --deu.[AñoAcad] = '2015' AND
                (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                --deu.PeriAcad = '01' AND -- Omitir
                deu.NumDI = @Num_DI ) BEGIN

            /*
            -- Var total de cuotas de pension de estudiante
            DECLARE @totalCuotaPension char(2)
            SELECT  @totalCuotaPension = COUNT(deu.NumCuota) FROM SGA.dbo.Deudas deu
            WHERE 
                deu.CondDeud IN (0,9) AND 
                deu.[AñoAcad] = '2015' AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.PeriAcad = '01' AND
                deu.NumDI = @Num_DI
            */

            -- Var incremento numeracion_operacion
            DECLARE @numMaxOpe INT;
            SELECT @numMaxOpe = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
            SET @numMaxOpe = @numMaxOpe + 1;

            -- Var conversion a char numeracion_operacion
            DECLARE @numMaxChar CHAR(9);
            SET @numMaxChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxOpe ))), 9);

            -- Var Codigo especialidad estudiante
            DECLARE @codEspEst VARCHAR(4);
            SELECT top 1 @codEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

            -- Var Sede estudio
            DECLARE @sedeEst VARCHAR(2);
            SELECT @sedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @Num_DI;

            -- Var Facultad_id en Opercarion campo Programa
            DECLARE @programa char(2);
            SELECT TOP 1 @programa = car.Fac_Id
            FROM SGA.dbo.Car_Carrera car
            INNER JOIN SGA.dbo.Operacion o on car.Fac_Id = o.programa
            WHERE o.NumDI = @Num_DI;

            INSERT INTO SGA.dbo.Operacion
                (
                SeriOper,NumOper,TipDI,NumDI,TipOper,
                FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat)
            VALUES
                (
                    @usuario_serie, @numMaxChar, '12', @Num_DI, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - ',
                    'ADMINISTRADOR', '01', @codEspEst, @sedeEst, @programa, '0',
                    NUll, NULL, NULL, NULL, NULL, NULL, NULL 
            );

            INSERT INTO SGA.dbo.DetOper
                (
                SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF)
            VALUES
                (
                    @usuario_serie, @numMaxChar, '001', '', 'D', 100, '', '',
                    '', '', '', '', '', '', '', '',
                    '', '', '', '', ''
            ),
                (
                    @usuario_serie, @numMaxChar, '002', '', 'D', 4, '', '',
                    '', '', '', '', '', '', '', '',
                    '', '', '', '', ''
            );

            -- Var 
            DECLARE @numMaxBoleta int;
            SELECT @numMaxBoleta = CONVERT(INT, NumBoleta) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
            SET @numMaxBoleta = @numMaxBoleta + 1;

            -- Var conversion a char numeracion
            DECLARE @numMaxBoletaChar CHAR(9);
            SET @numMaxBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxBoleta ))), 9);

            INSERT INTO SGA.dbo.NumeracionFE (SerieElec, NumeroElec, c_tipdoc, serie, dif)
            VALUES('B026', @numMaxBoletaChar, '06', @usuario_serie, '3');

            UPDATE SGA.dbo.Usuarios SET NumOper = @numMaxChar, NumBoleta = @numMaxBoletaChar WHERE Serie = @usuario_serie;

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
                UPDATE SGA.dbo.Deudas SET CondDeud = '2' WHERE SeriDeud = @Serie_Deu_Actual AND NumDeud = @Num_Deu_Actual;

                -- Obtener el siguiente registro
                FETCH NEXT FROM registros_cursor_deudas INTO @Serie_Deu_Actual, @Num_Deu_Actual 
            END;

            -- Cerrar y liberar el cursor
            CLOSE registros_cursor_deudas;
            DEALLOCATE registros_cursor_deudas;


        END 
        ELSE BEGIN
            -- Impedidios todos los cursos que pagaron sus cuotas

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

                -- SELECT distinct Cod_NotaCredDeb from SGA.dbo.Notas_Cred_Deb
                -- SELECT distinct Item from SGA.dbo.Notas_Cred_Deb
                -- SELECT top 10 * from SGA.dbo.Notas_Cred_Deb

                -- SELECT top 10 * from SGA.dbo.TipoNotaCredito
                -- SELECT top 10 * from SGA.dbo.TipoNotaDebito

                -- select top 10 * from SGA.dbo.Notas_Cred_Deb ncd
                -- INNER JOIN SGA.dbo.Operacion o on ncd.SeriOpRef = o.SeriOper and ncd.NumOpRef = o.NumOper
                -- where o.SeriOper = '8888'
                
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

                        /*
                        select top 10 * from SGA.dbo.Usuarios 
                        select top 10 * from SGA.dbo.Operacion o  

                        select top 10 * from SGA.dbo.NumeracionFE where serie = '8888'

                        select distinct SerieElec from SGA.dbo.NumeracionFE where serie = '8888'
                        select top 10 * from SGA.dbo.Notas_Cred_Deb 
                        select distinct Serie_Nota from SGA.dbo.Notas_Cred_Deb where SeriOper = '8888'


                    
                        SELECT top 10 * from SGA.dbo.Notas_Cred_Deb
                        select top 10 * from SGA.dbo.Operacion where (Serie_FE <> '' OR Serie_FE <> null) AND (Numero_FE <> '' or Numero_FE <> null)
                



                        select distinct TipOper from SGA.dbo.Operacion
                        select distinct TipDI from SGA.dbo.Operacion
                        select distinct AnulOper from SGA.dbo.Operacion
                        select distinct TipDoc from SGA.dbo.Operacion
                        select distinct programa from SGA.dbo.Operacion


                        select * from SGA.dbo.TipOper
                        SELECT* from SGA.dbo.TipoDocOper

                    -- SELECT top 10 * FROM SGA.dbo.Notas_Cred_Deb 
                    -- select top 10 * from dbo.Usuarios where Serie = '0100' 
                    -- SELECT top 10 * from dbo.NumeracionFE where serie = '0100'
                    SELECT distinct SerieElec from SGA.dbo.NumeracionFE where serie = '8888'
                    SELECT top 10 * from SGA.dbo.DatosUsuario
                    
                    

                    SELECT * from SGA.dbo.TipoNotaCredito
                    SELECT top 10
                        ncd.SeriOper, ncd.NumOper,
                        ncd.Serie_Nota, ncd.Numero_Nota,
                        ncd.SeriOpRef, ncd.NumOpRef,
                        o.SeriOper, o.NumOper,
                        o.Serie_FE, o.Numero_FE
                    FROM SGA.dbo.Notas_Cred_Deb ncd 
                    INNER JOIN SGA.dbo.Operacion o on ncd.SeriOpRef = o.SeriOper and ncd.NumOpRef = o.NumOper

                    select top 10 * from SGA.dbo.Notas_Cred_Deb

                    */
                    

                END 
                ELSE BEGIN
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