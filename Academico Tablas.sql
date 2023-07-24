
use DBCampusNet;

-- Tablas principales Academico
select top 100
    *
from dbo.Mtr_Matricula;
-- Matricula
select top 100
    *
from dbo.MMa_ModMatricula
;-- Modalidad Matricula
select top 100
    *
from dbo.MAc_ModAcademica;
-- Modalidad Academica {01: "Presencial", 07: "Semipresencial", 09: "Distancia"}

select top 1000
    *
from dbo.TAc_TipActa
;
-- Tipo de acta

select top 100
    *
from dbo.Fac_Facultad;
-- Facultad
select top 100
    *
from dbo.Sed_Sede;
-- Sede; Trabajando actualmente {"HU": "Huancayo", "FC": "Chanchamayo"}
select top 200
    *
from dbo.Car_Carrera;
-- Carrera
select top 30000
    *
from dbo.Asi_Asignatura;
-- Asignatura Desde el plan 1984 al 2022
select top 10000
    *
from General.TM_asi_Asignatura;
-- Asignatura Desde el plan 2015 al 2022
select top 2000
    *
from dbo.Aul_Aula;
-- Aula

select top 100
    *
from dbo.Nta_Nota;
-- Nota; Desde 2009 al 2023
select top 100
    *
from dbo.NtH_Nota_Hi;
-- Nota; Desde 1984 al 2008

select top 1000
    *
from dbo.Est_Estudiante;
-- Estudiante
select top 1000
    *
from dbo.Est_Estudiante_Auxliar;
-- Estudiante datos Auxiliares

select top 10
    *
from Academico.TM_ConvalidacionesTemp
;
-- Convalidaciones
select top 10
    *
from Academico.TD_ConvalidacionesTemp;
-- Convalidaciones detalle

-- INICIO

-- Var total notas curso
DECLARE @TotalNotasCurso int;
-- Var Total cursos matriculados
DECLARE @TotalCursosMatriculados int;

DECLARE @Num_DI varchar(15) = 'A621524';
DECLARE @usuario_serie char(4) = '8888';

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
                deu.NumDI = @Num_DI ) BEGIN

            /* Impedidios todos los cursos que no pagaron sus cuotas */

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

            -- Var incremento numeracion_operacion
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
                Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat)
            VALUES
                (
                    @usuario_serie, @numMaxOperChar, '12', @Num_DI, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - Condonacion deuda 2015-I a 2022-II',
                    'ADMINISTRADOR', '01', @codEspEst, @sedeEst, @programa, '0',
                    NUll, 'B026', @numMaxBoletaChar, NULL, NULL, NULL, NULL 
            );

            -- Var maximo año academico que no pago las cuotas
            DECLARE @maxAnioNoPagoCuotas CHAR(4);
            SELECT @maxAnioNoPagoCuotas = MAX(AñoAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') ;

            -- Var maximo periodo academico que no pago las cuotas
            DECLARE @maxPeriAcadDeuda CHAR(4);
            SELECT @maxPeriAcadDeuda = MAX(PeriAcad) FROM SGA.dbo.Deudas WHERE NumDI = @Num_DI AND CondDeud  in ('1', '9') AND [AñoAcad] = @maxAnioNoPagoCuotas;

            -- Var maximope
            

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
            

            -- Var incremento numeracion_operacion
            -- DECLARE @numMaxBoleta int;
            -- SELECT @numMaxBoleta = CONVERT(INT, NumBoleta) FROM SGA.dbo.Usuarios WHERE Serie = @usuario_serie;
            -- SET @numMaxBoleta = @numMaxBoleta + 1;

            -- -- Var conversion a char numeracion boleta
            -- DECLARE @numMaxBoletaChar CHAR(9);
            -- SET @numMaxBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @numMaxBoleta ))), 9);

            INSERT INTO SGA.dbo.NumeracionFE (SerieElec, NumeroElec, c_tipdoc, serie, dif)
            VALUES('B026', @numMaxBoletaChar, '06', @usuario_serie, '3');

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




use SGA

SELECT top 10
    *
FROM SGA.dbo.Deudas;
select top 10
    *
from SGA.dbo.Operacion;
select top 10
    *
from SGA.dbo.DetOper

select  top 10 * from SGA.dbo.Notas_Cred_Deb WHERE SeriOpRef = '8888'
select distinct Serie_Nota from SGA.dbo.Notas_Cred_Deb WHERE SeriOpRef = '8888';


select distinct SerieElec from SGA.dbo.NumeracionFE WHERE serie = '8888';
select  top 10 * from SGA.dbo.NumeracionFE WHERE serie = '8888'

SELECT top 10 * from SGA.dbo.NumeracionFE WHERE SerieElec = 'B001' AND NumeroElec = '00015790'

select top 10 *
from dbo.NumeracionFE nfe
inner join SGA.dbo.Operacion o on nfe.SerieElec = o.Serie_FE AND nfe.NumeroElec = o.Numero_FE AND nfe.serie = o.SeriOper


--WHERE SerieElec='B001' AND NumeroElec = '00071769' and serie = '0013'


select top 10 *
from dbo.NumeracionFE
WHERE SerieElec='B001' AND NumeroElec = '00071769' and serie = '0013'

select *
from Operacion o
where o.SeriOper = '0013' and o.NumOper = '000465588'

select *
from DetOper
where SeriOper = '0013' and NumOper = '000465588'

SELECT top 10  * from SGA.dbo.Notas_Cred_Deb

select top 10 * from SGA.dbo.NumeracionFE nfe 
inner join SGA.dbo.DetOper do on TRIM(nfe.SerieElec)+TRIM(nfe.NumeroElec) = TRIM(do.Comprobante)


select
    do.CodContab,
    plc.l_cuen
from DetOper do
    inner join dbo.PlanContab plc on do.CodContab = plc.c_cuen
where SeriOper = '0013' and NumOper = '000465588'

select *
from PlanContab

select top 10
    *
from dbo.Deudas
WHERE SeriDeud='0013' and NumDeud = '000465588'

use SGA

select
    plc.l_cuen,
    deu.CondDeud,
    Cdeu.DesCondDeud

from dbo.Deudas deu
    inner join dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    inner join dbo.CondDeud Cdeu on deu.CondDeud =Cdeu.CondDeud
WHERE deu.NumDI = 'f10102e' and deu.[AñoAcad] = 2018 AND deu.PeriAcad = '02'

select
    deu.Importe,
    plc.l_cuen,
    deu.CondDeud,
    Cdeu.DesCondDeud,
    deu.NumCuota

from dbo.Deudas deu
    inner join dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    inner join dbo.CondDeud Cdeu on deu.CondDeud =Cdeu.CondDeud
WHERE deu.NumDI = 'f10102e' and deu.[AñoAcad] = 2018 AND deu.PeriAcad = '02'

select top 10
    *
from dbo.ConcMatr;
select *
from dbo.CodContMatr;
select *
from dbo.CondDeud;

select
    deu.Importe,
    plc.l_cuen,
    deu.CondDeud,
    Cdeu.DesCondDeud,
    deu.NumCuota

from dbo.Deudas deu
    inner join dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    inner join dbo.CondDeud Cdeu on deu.CondDeud =Cdeu.CondDeud
WHERE deu.CondDeud in (9);


SELECT
    --*
    plc.l_cuen
FROM SGA.dbo.Deudas deu
    INNER JOIN SGA.dbo.PlanContab plc on deu.CodContab = plc.c_cuen
WHERE 
    deu.CondDeud IN (0,9) AND
    deu.NumCuota in (01, 02, 03, 04, 05) AND
    (deu.[AñoAcad] BETWEEN '2015' and '2022') AND
    --plc.l_cuen like '%PENSION%' AND
    deu.NumDI = 'A621524'

select top 10
    *
from Operacion o
    inner join dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
    inner join dbo.NumeracionFE ne on ne.serie = o.SeriOper
where 
    do.Comprobante like 'b010%'



select top 10
    -- o.SeriOper,
    -- o.NumOper,
    -- do.SeriOper,
    -- do.NumOper,
    -- ne.serie,
    o.Serie_FE,
    o.Numero_FE,
    ne.SerieElec,
    ne.NumeroElec,
    do.Comprobante,
    do.Comprobante_REF,
    do.DocRef,
    deu.DocCanc
from Operacion o
    inner join SGA.dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
    inner join SGA.dbo.NumeracionFE ne on ne.serie = o.SeriOper
    inner join SGA.dbo.Deudas deu on do.SeriOper+do.NumOper = deu.DocCanc
where 
    do.Comprobante = 'B01000000001'

-- Relacion Deudad con Operacion
select top 10
    o.SeriOper,
    o.NumOper,
    o.SeriOper+o.NumOper 'Relacion',
    deu.DocCanc
from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.Operacion o on deu.DocCanc = o.SeriOper+o.NumOper

-- Relacion Deudad con Detalle de Operacion
select top 10
    do.SeriOper,
    do.NumOper,
    do.SeriOper+do.NumOper 'Relacion',
    deu.DocCanc
from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.DetOper do on deu.DocCanc = do.SeriOper+do.NumOper


-- Relacion Detalle Operacion con Previo Comprobante de Facturación
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B00100071769'


select top 10 
    pfe.idComprobanteElectronico,
    pfe.idComprobante,
    do.SeriOper,
    do.NumOper
from SGA.dbo.DetalleComprobante_Maestra pfe 
INNER JOIN SGA.dbo.DetOper do on pfe.idComprobante = do.SeriOper+do.NumOper
where idComprobanteElectronico = 'B00100071769'

-- Relacion Numeracion
select top 10 * from SGA.dbo.NumeracionFE where SerieElec = 'B001' and NumeroElec = '00071769'
select top 10 * from SGA.dbo.Control_EnvioElect where cSerie = 'B001' and cNumero = '00071769'

select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B00100071769'

select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'BB0100015790'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200330454'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B00100071769'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B00100071769'




SELECT top 10 * from SGA.dbo.Estado_EnvioElec
SELECT top 10 * from SGA.dbo.FE_Estado_EnvioElec

SELECT top 10 * from SGA.dbo.Control_EnvioElect

select top 10 * from SGA.dbo.DetOper where SeriOper = '0013' and NumOper = '000465588'


select top 10
    *
from dbo.Deudas deu
    INNER JOIN dbo.DetOper do on deu.SeriDeud = do.SeriOper AND deu.NumDeud = do.NumOper
WHERE deu.SeriDeud = '8888'

-- Deuda y operacion por documento de cancelacion 
select
    deu.SeriDeud,
    deu.NumDeud,
    deu.DocCanc,
    do.SeriOper 'Serie DetOper',
    do.NumOper  'Numeracion  DetOper',
    o.SeriOper 'Serie Ope',
    o.NumOper 'Numeracion  Ope',
    nfe.serie,
    nfe.SerieElec,
    nfe.NumeroElec
from dbo.Deudas deu
    INNER JOIN dbo.DetOper do on deu.DocCanc = do.SeriOper+do.NumOper
    INNER JOIN dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
    INNER join dbo.NumeracionFE nfe on do.SeriOper = nfe.serie
where deu.NumDI = 'f10102e' and deu.DocCanc like '0002%'
ORDER BY nfe.NumeroElec

select distinct DocCanc
from dbo.Deudas
select *
from dbo.Usuarios
where Serie = '0013'


select top 10
    *
from SGA.dbo.Car_Carrera
select top 10
    *
from SGA.dbo.Car_Carrera_codpro

SELECT top 10
    *
FROM SGA.dbo.Deudas;
select top 10
    *
from SGA.dbo.Operacion
where  NumDI = 'f10102e' and Serie_FE like 'B%';
select top 10
    *
from SGA.dbo.DetOper

select *
from SGA.dbo.Car_Carrera
select *
from SGA.dbo.Car_Carrera_codpro

select distinct programa
FROM dbo.Operacion
where programa = '16'
select top 10
    *
from Clientes

select top 10
    *
from dbo.PlanContab
WHERE c_cuen ='7551011'


/*

DECLARE @tablaDeuda TABLE (
SerieDeu char(4),
NumDeu char(8)
)

INSERT INTO @tablaDeuda (SerieDeu, SerieDeu)
SELECT SeriDeud, NumDeud FROM SGA.dbo.Deudas 
WHERE CondDeud IN (0,9) AND 
([AñoAcad] BETWEEN '2015' AND '2022') AND
NumCuota in (01, 02, 03, 04, 05) AND
NumDI = @Num_DI

*/

select top 10 * from SGA.dbo.Deudas

select Distinct PeriAcad from SGA.dbo.Deudas
select Distinct Mtr_Periodo from DBCampusNet.dbo.Nta_Nota

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

 SELECT top 10 * from SGA.dbo.DetOper

select * from SGA.dbo.FE_TipoDocumento
select top 10 * from SGA.dbo.Operacion where (Serie_FE <> null or Serie_FE <> '') and (Numero_FE <> null or Numero_FE <> '') and Serie_FE like 'B0%'

select top 10 * from SGA.dbo.DetOper do 
INNER join SGA.dbo.Operacion o  on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
INNER JOIN SGA.dbo.NumeracionFE nfe on TRIM(do.Comprobante) = TRIM(nfe.SerieElec)+TRIM(nfe.NumeroElec)
where  o.NumDI = 'f10102e' and nfe.serie = '0013' and o.NumOper = '000465588' 

select top 10 * from SGA.dbo.NumeracionFE were 

-- SELECT distinct Cod_NotaCredDeb from SGA.dbo.Notas_Cred_Deb
-- SELECT distinct Item from SGA.dbo.Notas_Cred_Deb
-- SELECT top 10 * from SGA.dbo.Notas_Cred_Deb

-- SELECT top 10 * from SGA.dbo.TipoNotaCredito
-- SELECT top 10 * from SGA.dbo.TipoNotaDebito

-- select top 10 * from SGA.dbo.Notas_Cred_Deb ncd
-- INNER JOIN SGA.dbo.Operacion o on ncd.SeriOpRef = o.SeriOper and ncd.NumOpRef = o.NumOper
-- where o.SeriOper = '8888'

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


select 
    do.SeriOper,
    do.NumOper,
    o.SeriOper, 
    o.NumOper,
    deu.DocCanc,
    do.DocRef
from SGA.dbo.DetOper do 
inner join SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
inner join SGA.dbo.Deudas deu on do.SeriOper+do.NumOper = deu.DocCanc
where do.DocRef = '000 01102014'

select top 10  * from SGA.dbo.Deudas
select top 10  * from SGA.dbo.Num_fisica where serie+numoper = '00001102014'
select top 10 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobante = '00001102014'
select top 10 * from SGA.dbo.Control_EnvioElect
select count(num_bolfac) from SGA.dbo.Num_fisica

