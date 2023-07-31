Go

CREATE PROCEDURE SP_PROCESO_CONDONACION(
    @codigo_est varchar(15),
    @anio_acad char(4),
    @periodo_acad varchar(2),
    @num_cuota char(2)
    --@ciclo_acad varchar(5),
    --@cuota_valor numeric(18,2)
)AS
BEGIN 
    -- total notas curso
    DECLARE @TotalNotasCurso int;
    -- Total cursos matriculados
    DECLARE @TotalCursosMatriculados int;

    DECLARE @usuarioSerie char(4) = '8888';
    DECLARE @serieBoleta char(4) = 'B026';
    DECLARE @serieNotaCreito char(4) = 'BA26';

    SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE Mtr_Anio = @anio_acad AND
        Mtr_Periodo = @periodo_acad AND
        Nta_Promedio = 'im' AND
        --Nta_Seccion in ('I', 'E', 'S') and 
        Est_Id = @codigo_est;  

    IF @TotalNotasCurso = 0 AND @TotalCursosMatriculados = 0 BEGIN
        RETURN 'No se encontro registro de matricula';
    END
    ELSE BEGIN
        IF @TotalNotasCurso = @TotalCursosMatriculados  AND  @TotalNotasCurso > 0 AND @TotalCursosMatriculados > 0 BEGIN
            /* Impedido todos los cursos que no pago su cuota */

            -- Periodo agregar un cero delante
            DECLARE @DeudaPeriodoA char(2);
            SET @DeudaPeriodoA = CONCAT('0', @periodo_acad);

            -- Pumero cuota agregar un cero delante
            DECLARE @DeudaNumCuota char(2);
            SET @DeudaNumCuota = CONCAT('0', @num_cuota);


             


            IF EXISTS(select * from SGA.dbo.Operacion o 
                        INNER JOIN SGA.dbo.Deudas deu on o.SeriOper+o.NumOper = deu.DocCanc
                        WHERE 
                            deu.[AñoAcad] = @anio_acad AND
                            deu.PeriAcad = @DeudaPeriodoA AND
                            deu.NumCuota = @DeudaNumCuota AND
                            deu.CondDeud in (0,9) AND
                            deu.NumDI = @codigo_est ) BEGIN

            

                /* Impedidios todos los cursos que no pagaron sus cuotas */

                 -- Incremento numeracion_operacion
                DECLARE @NumOper INT;
                SELECT @NumOper = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;
                SET @NumOper = @NumOper + 1;   

                 -- Conversion a char numeracion_operacion
                DECLARE @NumOperChar CHAR(9);
                SET @NumOperChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @NumOperChar ))), 9);

                 -- Especialidad estudiante
                DECLARE @CodEspEst VARCHAR(4);
                SELECT top 1 @CodEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Sede estudio estudiante
                DECLARE @SedeEst VARCHAR(2);
                SELECT @SedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Programa  de modalidad academica
                DECLARE @Programa char(2);
                SELECT top 1 @Programa = MAC_id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Numeracion_boleta
                DECLARE @NumBoletaChar char(4);
                SELECT @NumBoletaChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuarioSerie AND SerieElec = @serieBoleta;

                INSERT INTO SGA.dbo.Operacion
                (
                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat)
                VALUES
                (
                    @usuarioSerie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - Condonacion deuda 2015-I a 2022-II',
                    'ADMINISTRADOR', '01', @CodEspEst, @SedeEst, @Programa, '0',
                    NUll, @serieBoleta, @NumBoletaChar, NULL, NULL, NULL, NULL 
                );

                

                -- Serie, numeracion y codContab deuda
                DECLARE @DeudaSerie CHAR(4);
                DECLARE @DeudaNum CHAR(8);
                DECLARE @DeudaCodContab char(14);

                select top 1 @DeudaSerie = SeriDeud, @DeudaNum = NumDeud, @DeudaCodContab = CodContab
                from SGA.dbo.Deudas
                WHERE   [AñoAcad] = @anio_acad AND
                        PeriAcad = @DeudaPeriodoA AND
                        NumCuota = @DeudaNumCuota AND
                        CondDeud in (0,9) AND
                        NumDI = @codigo_est;

                INSERT INTO SGA.dbo.DetOper
                (
                    SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                    PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                    codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                )
                VALUES
                (
                    @usuarioSerie, @NumOperChar, '001', @DeudaCodContab, 'D', 100, @DeudaNumCuota, @anio_acad,
                    @DeudaPeriodoA, @DeudaSerie+@DeudaNum, @DeudaCodContab, '', '', '', '', '',
                    '', '', '3', '', '', ''
                ),
                (
                    @usuarioSerie, @NumOperChar, '002', '', 'D', 4, @DeudaNumCuota, @anio_acad,
                    @DeudaPeriodoA, @DeudaSerie+@DeudaNum, '', '', '', '', '', '',
                    '', '', '3', '', '', ''
                );

                

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
                    @serieBoleta+@NumBoletaChar, @DeudaSerie+@DeudaNum, CONVERT(DATETIME, GETDATE(), 120), '', 'PEN', '',
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
                    @serieBoleta+@NumBoletaChar, @DeudaSerie+@DeudaNum, '', '', 'NIU', '01',
                    '', 100, 0, '01', 10, 0,
                    0, 0, 0, 104, 104
                ), (
                    @serieBoleta+@NumBoletaChar, @DeudaSerie+@DeudaNum, '', '', 'NIU', '02',
                    '', 4, 0, '01', 10, 0,
                    0, 0, 0, 104, 104
                )

                -- NewNumBoleta INT y NewNumBoletaChar CHAR(9) 
                DECLARE @NewNumBoleta INT, @NewNumBoletaChar char(9);
                SET @NewNumBoleta = CAST(@NumBoletaChar AS INT) + 1;
                SET @NewNumBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @NewNumBoleta ))), 9);

                UPDATE SGA.dbo.NumeracionFE SET NumeroElec = @NewNumBoletaChar WHERE serie = @usuarioSerie AND SerieElec = @serieBoleta

                UPDATE SGA.dbo.Usuarios SET NumOper = @NumOperChar WHERE Serie = @usuarioSerie;


                select top 100 * from SGA.dbo.Notas_Cred_Deb where SeriOper = '8888'

                select top 100 * from SGA.dbo.NumeracionFE where serie = '8888' and SerieElec = 'BA26'  


                

                
                RETURN ''

            END
            ELSE BEGIN
                /* Impedido todos los cursos que pago su cuota */
                RETURN ''
            END
        END
        ELSE BEGIN
            RETURN 'No se hiso impedir en todos los cursos'
        END
    END


END

select top 10 * from SGA.dbo.Operacion 
select top 10 * from SGA.dbo.DetOper


SELECT *
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE (Mtr_Anio BETWEEN '2015' AND '2022') AND -- Mtr_Anio = '2015' and
        Mtr_Periodo in (1, 2) and  -- Mtr_Periodo = 1 and -- Omitir
        --Nta_Promedio = 'im' AND
        --Nta_Seccion in ('I', 'E', 'S') and 
        Est_Id = 'A621524' 

 -- Var total notas curso
-- DECLARE @TotalNotasCurso int;
-- -- Var Total cursos matriculados
-- DECLARE @TotalCursosMatriculados int;        

SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE Mtr_Anio = '2015' AND --(Mtr_Anio BETWEEN '2015' AND '2022') AND -- Mtr_Anio = '2015' and
        Mtr_Periodo = '2' AND  -- Mtr_Periodo = 1 and -- Omitir
        Nta_Promedio = 'im' AND
        --Nta_Seccion in ('I', 'E', 'S') and 
        Est_Id = 'A621524'; 

SELECT  @TotalNotasCurso, @TotalCursosMatriculados

SELECT distinct Mtr_Anio from DBCampusNet.dbo.Nta_Nota 

SELECT distinct [AñoAcad] from SGA.dbo.Deudas

SELECT * 
        FROM SGA.dbo.Deudas deu
            WHERE
                deu.[AñoAcad] = '2015' AND
                deu.PeriAcad = '02' AND
                -- (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
                deu.CondDeud IN (0,9) AND
                deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.NumDI = 'A621524'


SELECT top 10 * from SGA.dbo.PensionesxCobrar 
where SeriDeud = '8888' and NumDeud = '00855589'

SELECT top 10 * from SGA.dbo.Num_fisica where num_bolfac = '1010190048'
SELECT top 10 * from SGA.dbo.Num_fisica where serie = '8888' and numdeud = '00855589' 

SELECT top 10 * from SGA.dbo.Operacion 
where NumComFisico = '1010190048  '



select * from SGA.dbo.Deudas deu 
INNER JOIN SGA.dbo.Comprobantes_Mestra cm on deu.SeriDeud+deu.NumDeud = cm.idComprobante
WHERE     
    deu.[AñoAcad] = '2018' AND
    deu.PeriAcad = '01' AND
    -- (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
    --deu.CondDeud IN (0,9) AND
    --deu.NumCuota in (01, 02, 03, 04, 05) AND
    deu.NumDI = 'f10102e'


SELECT * 
        FROM SGA.dbo.Deudas deu
            WHERE 
        
                deu.[AñoAcad] = '2018' AND
                deu.PeriAcad = '01' AND
                -- (deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
                --deu.CondDeud IN (0,9) AND
                --deu.NumCuota in (01, 02, 03, 04, 05) AND
                deu.NumDI = 'f10102e' and DocCanc = '0002001075903'




select * from SGA.dbo.NumeracionFE where serie = '8888'

select count(CodContab) from SGA.dbo.Cuentasdecuotas
select * from SGA.dbo.NumeracionFE where serie = '8888'

select count(CodContab) from SGA.dbo.Cuentasdecuotas
slect 

select top 10 * from SGA.dbo.PlanContab where c_cuen = '6595257'
select  distinct MAC_id from SGA.dbo.clientes
select * from SGA.dbo.MAc_ModAcademica

select top 10 * from SGA.dbo.deudas 
where   NumDI = 'f10102e' AND
        [AñoAcad] = '2018' AND
        PeriAcad = '01' AND 
        NumCuota in ('01', '02', '03', '04', '05')

-- Doc Cancelacion 0002001075903

select * from SGA.dbo.DetOper where DocRef = '888801668228'

select * from SGA.dbo.Deudas where SeriDeud = '8888' AND NumDeud = '01668228'

select top 10 * from SGA.dbo.Operacion WHERE SeriOper+NumOper = '0002001075903'
select top 10 * from SGA.dbo.DetOper WHERE SeriOper+NumOper = '0002001075903'

select top 100 * from SGA.dbo.Operacion WHERE NumComFisico <> 0 or NumComFisico <> null or NumComFisico <> '' and NumComFisico = '8888'


select top 10 * from SGA.dbo.DetOper WHERE SeriOper+NumOper = '0002001075903'

select * from SGA.dbo.Cuotas_Adicionales
select * from SGA.dbo.Cuentasdecuotas
select top 1000 * from SGA.dbo.Num_fisica


DECLARE @FechaInicio DATE = '2023-07-15'
DECLARE @FechaFin DATE = '2023-07-24'

DECLARE @DiasDiferencia INT
SET @DiasDiferencia = DATEDIFF(day, '2018-04-30', '2018-05-08')

SELECT @DiasDiferencia  * 0.0005 AS DiferenciaEnDias


-- deudas de estudiante
select * from SGA.dbo.Deudas deu 
where   deu.[AñoAcad] = '2015' AND
        deu.PeriAcad = '02' AND
        deu.NumCuota = '04' AND
        deu.CondDeud in (0,9) AND
        deu.NumDI = 'A621524'

-- serie y numeracion deuda
DECLARE @SerieDeuda char(4), @NumeracionDeuda char(8)
select 
    @SerieDeuda = SeriDeud,
    @NumeracionDeuda = NumDeud
from SGA.dbo.Deudas deu 
where   deu.[AñoAcad] = '2015' AND
        deu.PeriAcad = '02' AND
        deu.NumCuota = '04' AND
        deu.CondDeud in (0,9) AND
        deu.NumDI = 'A621524'
        --deu.NumDI = 'f10102e'

-- SELECT @SerieDeuda, @NumeracionDeuda

-- SerieOper, NumOper y DocRef
DECLARE  @SerieOperacion char(4), @NumeracionOperacion char(9), @DocRefDetalleOper char(12)
SELECT @SerieOperacion = SeriOper, @NumeracionOperacion = NumOper, @DocRefDetalleOper = DocRef from SGA.dbo.DetOper
where DocRef = @SerieDeuda+@NumeracionDeuda

-- SELECT @SerieOperacion, @NumeracionOperacion, @DocRefDetalleOper

update SGA.dbo.Deudas SET CondDeud = '1' 

select top 10 * from SGA.dbo.Deudas 

select distinct CondDeud from SGA.dbo.Deudas
SELECT * FROM SGA.dbo.CondDeud 



Update SGA.dbo.Deudas SET CondDeud = '2', DocCanc = @SerieOperacion+@NumeracionOperacion
WHERE   [AñoAcad] = '2015' AND
        PeriAcad = '02' AND
        NumCuota = '04' AND
        CondDeud in (0,9) AND
        NumDI = 'A621524'


SELECT top 10 * from SGA.dbo.Operacion where NumDI = 'f10102e' and (FecOper BETWEEN '2018-01-01' and '2018-12-31') and TipOper = '00'

SELECT * from SGA.dbo.TipOper
SELECT * from SGA.dbo.CondDeud

SELECT o.SeriOper, o.NumOper, o.Declarado_Sunat, o.TotOper, do.item
FROM SGA.dbo.Operacion o
INNER JOIN SGA.dbo.DetOper do on o.SeriOper = do.SeriOper AND o.NumOper = do.NumOper
WHERE 
        --do.[AñoAcad] = @maxAnioPagoCuotas AND
        o.NumDI = @codigo_est AND
        do.NumCuota in ('01', '02', '03', '04', '05');

SELECT top 10 * from SGA.dbo.Deudas
where   
        AñoAcad = '2015' AND
        PeriAcad = '01' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'A20362F'

-- serie numeracion deuda
-- 8888 00855589
--      00855590


select top 100 * from SGA.dbo.DetOper do
INNER JOIN SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
WHERE   o.NumDI = 'A20362F' AND
        do.AñoAcad = '2018' AND
        do.PeriAcad = '01' AND
        do.NumCuota in ('01', '02', '03', '04', '05')
        -- o.NumDI = 'A621524'


SELECT top 10 * from SGA.dbo.Operacion
where   NumDI = 'A621524' AND
        FecOper BETWEEN '2015-08-01' AND '2015-12-31'

select top 10 * from SGA.dbo.DetOper WHERE DocRef = '888800855590'


select top 10 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobante = '888801779070'
/* ------------------------------- */

-- DEUDA GENERADA A ESTUDIANTE

SELECT top 100 * from SGA.dbo.Deudas
where   
        AñoAcad = '2015' AND
        PeriAcad = '02' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'A621524'

-- serie y numeracion de deuda
/*  

    -- A621524 --

    8888 00855589  
    8888 00855590
    8888 00855591
    8888 00855592


    -- A20362F --

    8888 01779070
    8888 01779071


    -- A50380B --

    8888 02217487 -
    8888 02217488
    8888 02217489
    8888 02217490
    8888 02217491

    -- J03932K --
    8888 02736461
    8888 02736462
    8888 02736463
    8888 02736464
    8888 02736465

*/

-- PENSIONES POR COBRAR
SELECT top 10 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '01779070'

SELECT top 10 * from SGA.dbo.Operacion WHERE Serie_FE+Numero_FE = 'B01200359217'

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200359217'

SELECT top 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'B01200359217'

    -- Comprobantes: 1010190048, 1120126803, 1120167925, 1060011992

    SELECT top 10 * from SGA.dbo.Num_fisica WHERE num_bolfac = '1010190048'
    select top 10 * from SGA.dbo.Operacion WHERE NumComFisico = '1010190048'

    select top 10 * from SGA.dbo.Operacion 

/**/

    SELECT top 10 * from SGA.dbo.Operacion WHERE Serie_FE+Numero_FE = 'B01200359217'
    SELECT top 10 * from SGA.dbo.DetOper WHERE Comprobante = 'B01200919841'

    SELECT top 10 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobanteElectronico = 'B01200919841'
    SELECT top 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'B01200919841'

/**/

select top 10 * from SGA.dbo.Operacion WHERE NumComFisico like '1060011992%'

SELECT top 10 * from SGA.dbo.Num_fisica WHERE num_bolfac like '1060011992'
SELECT top 10 * from SGA.dbo.Num_fisica WHERE serie+numoper like '1010190048'
SELECT top 10 * from SGA.dbo.Num_fisica WHERE referencia like '%1010190048%'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobante = '888800855589' 

SELECT top 10 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '00855589'

IF EXISTS(SELECT  * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '00855589' and Comprobante like 'B%') BEGIN
    SELECT 'EXISTE'
END
ELSE BEGIN
    SELECT 'no existe'
END


-- COMPROBANTE GENERADO A DEUDA
SELECT top 100 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobante = '888802736461'
SELECT top 100 * from SGA.dbo.DetalleComprobante_Maestra WHERE idComprobante = '888802736461'

SELECT top 100 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobanteElectronico = 'B01200919841'

SELECT top 100 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '02736461'

-- OPERACION GENERADA
SELECT top 10 * from SGA.dbo.Operacion where Serie_FE+Numero_FE = 'B01200598963'
SELECT top 10 * from SGA.dbo.DetOper where Comprobante = 'B01200598963'
SELECT top 10 * from SGA.dbo.DetOper where DocRef = '888802217487'

-- SERIE Y NUMERACION DE OPERACION
SELECT TOP 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000599120'
SELECT TOP 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000599120'

-- CONTROL FE
SELECT TOP 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'B01200598963'

-- Comprobantes fisicos
SELECT top 100 * from SGA.dbo.Num_fisica WHERE serie = '8888' and numdeud = '00855589'
SELECT top 100 * from SGA.dbo.Num_fisica where numdeud like '8%'

-- 


/*  */
-- Serie y Numeracion de Deuda
DECLARE @SerieDeu char(4), @NumeracionDeu char(8)

SELECT @SerieDeu = SeriDeud, @NumeracionDeu = NumDeud from SGA.dbo.Deudas
where   
        AñoAcad = '201' AND
        PeriAcad = '02' AND
        NumCuota = '01' AND -- in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'A50380B'

SELECT @SerieDeu, @NumeracionDeu

SELECT * from SGA.dbo.DetOper where DocRef = '888802217487' 
SELECT * from SGA.dbo.Comprobantes_Mestra where idComprobante = '888802217487' 

SELECT top 10 * from SGA.dbo.PlanContab where c_cuen = '1273013'

DECLARE @IdComprobanteElectronico VARCHAR(20);
SELECT  @IdComprobanteElectronico = idComprobanteElectronico from SGA.dbo.Comprobantes_Mestra where  idComprobante = @SerieDeu+@NumeracionDeu

IF EXISTS (SELECT * from SGA.dbo.Comprobantes_Mestra where  idComprobante = @SerieDeu+@NumeracionDeu) BEGIN
    select 'existe'
END
ELSE BEGIN 
    select 'no existe'
END

SELECT top 10 * from SGA.dbo.Control_EnvioElect WHERE cSerie+cNumero = @IdComprobanteElectronico

SELECT top 10 * from SGA.dbo.Control_EnvioElect

SELECT distinct Estadosunat from SGA.dbo.Comprobantes_Mestra

IF EXISTS (SELECT top 100 * from SGA.dbo.Deudas
            WHERE   
                    AñoAcad = '2015' AND
                    PeriAcad = '02' AND
                    NumCuota in ('01', '02', '03', '04', '05') AND
                    CondDeud in (0, 9) and
                    NumDI = 'A621524') BEGIN 

    PRINT 'EXISTE'
    
END
ELSE BEGIN 
    PRINT 'NO EXISTE'
END


SELECT top 1000 * from SGA.dbo.Clientes where Cli_Paterno = 'POMA' and CodEspe = '014' and sed_id = 'HU'


select * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00830036';
select * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00830036';
select * from SGA.dbo.Comprobantes_Mestra where idComprobante = '888800830036'; 
select * from SGA.dbo.Comprobantes_Mestra where idComprobante = '1010185727'; 

SELECT top 10 * from SGA.dbo.Operacion WHERE NumComFisico = '1010185727'

Select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855589'


SELECT top 10 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '00855589'
/*
   Comprobante --> Sin serie y numeracion de facturación
    1010190048
*/
select top 10 * from SGA.dbo.Operacion WHERE NumComFisico = '1010190048'
select top 10 * from SGA.dbo.DetOper

select top 10 * from SGA.dbo.Operacion where TRIM(NumComFisico) = '1010190048'

select top 10 * from SGA.dbo.Operacion where NumComFisico like '00000%'
select Max(NumComFisico) from SGA.dbo.Operacion where NumComFisico like '00000%'

SELECT top 10 * from SGA.dbo.Num_fisica where serie = ''
SELECT distinct tipodoc from SGA.dbo.Num_fisica 

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where Trim(idComprobante) = '1010190048'

SELECT top 10 * from SGA.dbo.DetOper where Trim(Comprobante) = '1010190048' 
SELECT top 10 * from SGA.dbo.DetOper where Trim(DocRef) = '1010190048'

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra WHERE ENroDocumento = '1010190048'

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra WHERE RNroDocumento = '1010190048'

