
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
    DECLARE @serieNotaCredito char(4) = 'BA26';

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
           
            -- Periodo agregar un cero delante
            DECLARE @DeudaPeriodoA char(2);
            SET @DeudaPeriodoA = CONCAT('0', @periodo_acad);

            -- Numero cuota agregar un cero delante
            DECLARE @DeudaNumCuota char(2);
            SET @DeudaNumCuota = CONCAT('0', @num_cuota);


            -- Serie, Numeracion y CodContab de Deuda
            DECLARE @DeudaSerie char(4), @DeudaNumeracion char(8), @DeudaCodContab char(14);

            SELECT @DeudaSerie = SeriDeud, @DeudaNumeracion = NumDeud, @DeudaCodContab = CodContab from SGA.dbo.Deudas
            where   AñoAcad = @anio_acad AND
                    PeriAcad = @DeudaPeriodoA AND
                    NumCuota = @DeudaNumCuota AND -- in ('01', '02', '03', '04', '05') AND
                    CondDeud in (0, 9) and
                    NumDI = @codigo_est;
            
            -- Numeracion Operacion
            DECLARE @NumOperChar CHAR(9);
            SELECT @NumOperChar = NumOper FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;
            --SELECT @NumOperChar =  RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, NumOper) + 1 ))), 9) FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;


            -- Especialidad, Sede y Programa
            DECLARE @CodEspEst VARCHAR(4), @SedeEst VARCHAR(2), @Programa CHAR(2);
            SELECT top 1 @CodEspEst = CodEspe, @SedeEst = sed_id, @Programa = MAC_id  FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;


            IF EXISTS(SELECT * from SGA.dbo.Comprobantes_Mestra where  idComprobante = @DeudaSerie+@DeudaNumeracion ) BEGIN 
            -- SELECT  * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '00855589'
            -- SELECT  * from SGA.dbo.PensionesxCobrar WHERE Comprobante like 'B%'

                /* Existe Comprobante creado */
                
                -- IdComprobanteElectronico y TotalVenta de Comprobantes_Mestra
                DECLARE @IdComprobanteElectronico VARCHAR(20), @TotalVenta decimal(38,2);

                -- Serie, Numeracion y FE de Operacion 
                DECLARE @OperSerie char(4), @OperNumeracion char(9);

                SELECT  @IdComprobanteElectronico = idComprobanteElectronico, @TotalVenta=TotalVenta  FROM SGA.dbo.Comprobantes_Mestra where idComprobante = @DeudaSerie+@DeudaNumeracion;
                SELECT  @OperSerie = SeriOper, @OperNumeracion = NumOper from SGA.dbo.Operacion where Serie_FE+Numero_FE =  @IdComprobanteElectronico;

                -- Numeracion Nota credito
                DECLARE @NumNotaCreditoChar char(8);
                SELECT @NumNotaCreditoChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuarioSerie AND SerieElec = @serieNotaCredito;
        

                INSERT INTO SGA.dbo.Operacion
                (
                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                )
                VALUES
                (
                    @usuarioSerie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, -@TotalVenta, '1', 1, 'RECTIFICACIÓN DE COMPROBANTE EMITIDO '+@IdComprobanteElectronico+' POR CONDONACIÓN',
                    'ADMINISTRADOR', '--', @CodEspEst, @SedeEst, @Programa, '0',
                    30, @serieNotaCredito, @NumNotaCreditoChar, 'NC', NULL, NULL, NULL
                );


                /* Cursor detalle de operacion nota credito*/
                DECLARE @Item CHAR(3), @Importe NUMERIC(15,2);

                DECLARE C_DETOPER_NOTA_CREDITO  CURSOR FOR   
                SELECT Item, Importe
                    FROM SGA.dbo.DetOper
                    WHERE SeriOper = @OperSerie and NumOper = @OperNumeracion;

                OPEN C_DETOPER_NOTA_CREDITO;
    
                FETCH NEXT FROM C_DETOPER_NOTA_CREDITO INTO @Item, @Importe;
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
                        @usuarioSerie, @NumOperChar, @Item, '6595257', 'D', -@Importe, @DeudaNumCuota, @anio_acad,
                        @DeudaPeriodoA, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                        '--', '1', '7', @serieNotaCredito+@NumNotaCreditoChar, @IdComprobanteElectronico, '3'
                    );

                    FETCH NEXT FROM C_DETOPER_NOTA_CREDITO INTO @Item, @Importe;
                END

                CLOSE C_DETOPER_NOTA_CREDITO;
                DEALLOCATE C_DETOPER_NOTA_CREDITO;

                INSERT INTO SGA.dbo.Notas_Cred_Deb (
                    SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
                    Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
                )
                VALUES
                (
                    @usuarioSerie, @NumOperChar, CONVERT(date, GETDATE(), 120), @serieNotaCredito, @NumNotaCreditoChar, 'ANULACIÓN DE LA OPERACIÓN '+@IdComprobanteElectronico ,
                    @TotalVenta, 'NC', '01', '01', @OperSerie, @OperNumeracion
                );
                
                UPDATE SGA.dbo.NumeracionFE SET NumeroElec = RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, @NumNotaCreditoChar) + 1 ))), 8)where Serie = @usuarioSerie AND SerieElec =  @serieNotaCredito;

                UPDATE SGA.dbo.Usuarios Set NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  Where Serie = @usuarioSerie;


            END
            ELSE BEGIN

                -- Numeracion boleta
                DECLARE @NumBoletaChar char(4);
                SELECT @NumBoletaChar = NumeroElec FROM SGA.dbo.NumeracionFE WHERE serie = @usuarioSerie AND SerieElec = @serieBoleta;


                INSERT INTO SGA.dbo.Operacion
                (
                    SeriOper,NumOper,TipDI,NumDI,TipOper,
                    FecOper,HoraOper,AnulOper,TotOper,TipMoneda,TipCambio,Observac,
                    Usuario,TipDoc,Codespe,sede,programa,NumComFisico,
                    Cod_AfectaIGV,Serie_FE,Numero_FE,Tip_DocumentoTrib,Declarado_Sunat,Correlativo_Baja,Rechazado_Sunat
                )
                VALUES
                (
                    @usuarioSerie, @NumOperChar, '12', @codigo_est, '01', -- condonacion
                    CONVERT(smalldatetime, GETDATE(), 120), CONVERT(char(8), GETDATE(), 108), 0, 104, '1', 1, 'OBS - Condonacion deuda 2015-I a 2022-II',
                    'ADMINISTRADOR', '--', @CodEspEst, @SedeEst, @Programa, '--',
                    '30', @serieBoleta, @NumBoletaChar, 'BV', NULL, NULL, NULL 
                );

                INSERT INTO SGA.dbo.DetOper
                (
                    SeriOper,NumOper,item,CodContab,TipCodCont,Importe,NumCuota,AñoAcad,
                    PeriAcad,DocRef,ImpTransf,ImpDscto,PorDscto,dFecOper,itemtransf,cantidad,
                    codint,CondItem,TipoComp,Comprobante,Comprobante_REF,TIPDOC_REF
                )
                VALUES
                (
                    @usuarioSerie, @NumOperChar, '001', @DeudaCodContab, 'D', 100, @DeudaNumCuota, @anio_acad,
                    @DeudaPeriodoA, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NUll, 1,
                    '', '1', '3', '', '', '3'
                ),
                (
                    @usuarioSerie, @NumOperChar, '002', @DeudaCodContab, 'D', 4, @DeudaNumCuota, @anio_acad,
                    @DeudaPeriodoA, @DeudaSerie+@DeudaNumeracion, 0, 0, 0, CONVERT(smalldatetime, GETDATE(), 120), NULL, 1,
                    '', '1', '3', '', '', '3'
                );

                select * from SGA.dbo.PlanContab where l_cuen like '%TRAMITE%'

                SELECT top 10 * from SGA.dbo.Operacion o 
                INNER JOIN SGA.dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
                where o.TipOper = '01' and 
                        o.Tip_DocumentoTrib = 'NC'
                
                select * from SGA.dbo.TipOper
                SELECT * from SGA.dbo.TDo_TipDocumento




                UPDATE SGA.dbo.Usuarios Set NumOper = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), CONVERT(BIGINT, @NumOperChar) + 1 ))), 9)  Where Serie = @usuarioSerie;

            END

        END
        ELSE BEGIN
            RETURN 'No se hiso impedir en todos los cursos'
        END
        
    END
END



select distinct TIPDOC_REF from SGA.dbo.DetOper do 
inner JOIN SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
where o.NumDI = 'f10102e'

select * from SGA.dbo.TipoDocOper

select top 100 * from SGA.dbo.DetOper do 
inner JOIN SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
where o.NumDI = 'f10102e' and do.AñoAcad = 2018

select top 100 * from SGA.dbo.TipDcto

select top 100 * from SGA.dbo.TipDscto
select top 100 * from SGA.dbo.TipoDocOper

SELECT CONVERT(smalldatetime, GETDATE(), 120)

select RIGHT('00000000' + LTRIM(RTRIM(CONVERT(CHAR(8), CONVERT(BIGINT, '00000123') + 1 ))), 8)

select top 10 * from SGA.dbo.PensionesxCobrar

select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855589'
select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '02217491'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '1010190048' 

select distinct condItem from SGA.dbo.PensionesxCobrar
select distinct TipoComp from SGA.dbo.PensionesxCobrar
select distinct Declarado_Sunat from SGA.dbo.PensionesxCobrar
select distinct TipoAfecta from SGA.dbo.PensionesxCobrar



SELECT top 10 * from SGA.dbo.Control_EnvioElect

select * from SGA.dbo.TipoDocOper

SELECT distinct Cod_NotaCredDeb  from SGA.dbo.Notas_Cred_Deb

-- INSERT INTO SGA.dbo.Notas_Cred_Deb
-- (
--     SeriOper,NumOper,Fecha_Emision,Serie_Nota,Numero_Nota,Motivo,
--     Importe_Total,Tip_Nota,Cod_NotaCredDeb,Item,SeriOpRef,NumOpRef
-- )
-- VALUES
-- (
--     @usuarioSerie, @Num_Oper_Actual, CONVERT(date, GETDATE(), 120), 'BB26', @numMaxCreditoChar, 'Condonacion deuda',
--     @Total_Operacion, 'NC', '01', @Item_DetOper, @Serie_Oper_Actual, @Num_Oper_Actual
-- );

-- UPDATE SGA.dbo.Usuarios SET NumNCredito = @numMaxCreditoChar where Serie = @usuario_serie 

SELECT top 100 * from SGA.dbo.TDo_TipDocumento;
SELECT top 100 * from SGA.dbo.TipoDocOper;
select top 100 * from SGA.dbo.TipDcto
select top 100 * from SGA.dbo.TipDscto
select top 100 * from SGA.dbo.TipoNotaCredito

-- select top 10 * from SGA.dbo.Notas_Cred_Deb
-- select top 100 * from SGA.dbo.TipoNotaCredito
-- select top 100 * from SGA.dbo.TipoNotaDebito

-- select distinct Cod_NotaCredDeb from SGA.dbo.Notas_Cred_Deb
-- select distinct Item from SGA.dbo.Notas_Cred_Deb
-- select distinct SeriOpRef from SGA.dbo.Notas_Cred_Deb
-- select distinct NumOpRef from SGA.dbo.Notas_Cred_Deb

-- SELECT top 100 * from SGA.dbo.Comprobantes_Mestra WHERE idComprobante = '888802217487'
-- SELECT top 100 * from SGA.dbo.DetalleComprobante_Maestra WHERE idComprobante = '888802217487'
-- SELECT distinct CodigoItem from SGA.dbo.DetalleComprobante_Maestra

-- select top 10 * from SGA.dbo.PensionesxCobrar
-- select top 10 * from SGA.dbo.PensionesxCobrar_Anulados

-- select NumOper from SGA.dbo.Usuarios where Serie = '8888'
-- SELECT Max(NumOper) from SGA.dbo.Operacion where SeriOper = '8888'

 select top 10 * from SGA.dbo.PlanContab where c_cuen = '6595257'
select top 10 * from SGA.dbo.PlanContab where c_cuen = '6595258'
SELECT distinct TipDoc from SGA.dbo.Operacion

SELECT top 10 * from SGA.dbo.Notas_Cred_Deb nc 
INNER JOIN SGA.dbo.Operacion o on nc.SeriOper = o.SeriOper and nc.NumOper = o.NumOper
where nc.Tip_Nota = 'NC' and o.NumDI = 'f10102e';

SELECT top 10 * from SGA.dbo.DetOper where SeriOper = '0013' and NumOper = '000380847'

/*
    SeriOper NumOper
    0013 000380847

    SeriOpRef NumOpRef
    0002 000734757
*/

SELECT top 10 * from SGA.dbo.Operacion WHERE SeriOper = '0013' and NumOper = '000380847'
SELECT top 10 * from SGA.dbo.DetOper WHERE SeriOper = '0013' and NumOper = '000380847'

SELECT * from SGA.dbo.Operacion WHERE SeriOper = '0002' and NumOper = '000734757'
SELECT * from SGA.dbo.DetOper WHERE SeriOper = '0002' and NumOper = '000734757'


SELECT top 10 * from SGA.dbo.Comprobantes_Mestra WHERE IdDocumento = 'B01000023079' or idComprobanteElectronico = 'B01000023079'
SELECT top 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'B01000023079'

SELECT top 10 * from SGA.dbo.Control_EnvioElect_back where cSerie+cNumero = 'B01000023079'

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01000023079'
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01000023079'

select top 10 * from SGA.dbo.Deudas WHERE DocCanc = '0002000734757'

select top 10 * from SGA.dbo.PensionesxCobrar WHERE Comprobante = 'B01000023079'


--SELECT top 10 * from SGA.dbo.

SELECT TOP 10 * FROM SGA.dbo.PensionesxCobrar WHERE Comprobante = 'B01000023079'
SELECT top 10 * from SGA.dbo.Deudas where SeriDeud+NumDeud = '888801249954'

SELECT * from SGA.dbo.PlanContab where c_cuen = '7412010'

SELECT  distinct Tip_DocumentoTrib from SGA.dbo.Operacion WHERE SeriOper = '0100' and NumOper = '000044209'

-- select top 100 * from SGA.dbo.DetOper where Comprobante like 'BA%' and SeriOper = '8888'

-- select distinct TipoComp from SGA.dbo.DetOper where Comprobante like 'BA%' and SeriOper = '8888'

-- SELECT TOP 10 * FROM SGA.dbo.TipoDocOper

-- SELECT top 10 * from SGA.dbo.Deudas where SeriDeud+NumDeud = '888801435651'

 
-- Numeracion operacion
-- DECLARE @NumOper INT;
-- SELECT @NumOper = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;
-- SET @NumOper = @NumOper + 1;   

    -- Conversion a char numeracion_operacion
-- DECLARE @NumOperChar CHAR(9);
-- SET @NumOperChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @NumOperChar ))), 9);

-- Especialidad estudiante
-- DECLARE @CodEspEst VARCHAR(4);
-- SELECT top 1 @CodEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

-- -- Sede estudio estudiante
-- DECLARE @SedeEst VARCHAR(2);
-- SELECT @SedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

-- -- Programa  de modalidad academica
-- DECLARE @Programa char(2);
-- SELECT top 1 @Programa = MAC_id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;


SELECT distinct Declarado_Sunat from SGA.dbo.Operacion
SELECT * from SGA.dbo.TipAfectaIGV
SELECT * from SGA.dbo.Operacion o 
INNER JOIN SGA.dbo.DetOper do on o.SeriOper = do.SeriOper  and o.NumOper = do.NumOper
WHERE o.NumDI = 'f10102e' AND
        do.NumCuota = '01' AND
        do.PeriAcad = '01' AND
        do.[AñoAcad] = '2018' AND
        o.SeriOper = '0002' AND o.NumOper = '001075903'

SELECT * from SGA.dbo.DetOper do
WHERE do.NumCuota = '01' AND
        do.PeriAcad = '01' AND
        do.[AñoAcad] = '2018' AND
        do.SeriOper = '0002' AND do.NumOper = '001075903'

SELECT * from SGA.dbo.Operacion o
WHERE o.SeriOper = '0002' AND o.NumOper = '001075903'

SELECT distinct TipDoc From SGA.dbo.Operacion
SELECT * From SGA.dbo.TipOper
SELECT * From SGA.dbo.TipDcto
SELECT * From SGA.dbo.TipDscto
SELECT * From SGA.dbo.TipoDocOper

SELECT top 100 * from SGA.dbo.PensionesxCobrar WHERE Comprobante not like 'B%'

select top 10 * from SGA.dbo.Comprobantes_Mestra where  idComprobante = '010500114100'

SELECT top 100  * from SGA.dbo.Num_fisica  where fecha BETWEEN '2015-01-01' and '2015-12-31'

SELECT * from SGA.dbo.PlanContab where c_cuen = '1255103'
SELECT * from SGA.dbo.PlanContab where c_cuen = '1631011'


SELECT top 100 * from SGA.dbo.Deudas
where 
        AñoAcad = '2017' AND
        PeriAcad = '01' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'D10061I'
/*
    -- D10061I --
    8888 01349117
    8888 01349118
    8888 01349119
    8888 01349120
    8888 01349121
*/


select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '01349117' -- B01200051465
select top 10 * from SGA.dbo.Comprobantes_Mestra where IdDocumento  = 'B01200051465' or idComprobanteElectronico = 'B01200051465'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico  = 'B01200051465'
SELECT top 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'B01200051465'

select top 10 * from SGA.dbo.Operacion where Serie_FE+Numero_FE = 'B01200051465' -- PC01 000051470
select top 10 * from SGA.dbo.DetOper where Comprobante = 'B01200051465' 

select top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000051470' 
select top 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000051470'

--select top 10 * from SGA.dbo.Notas_Cred_Deb where SeriOper = 'PC01' and NumOper = '000051470'


SELECT top 100 * from SGA.dbo.Deudas
where 
        AñoAcad = '2015' AND
        PeriAcad = '02' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'A621524'
/*
    -- A621524 --
    8888 00855589  
    8888 00855590
    8888 00855591
    8888 00855592
*/

select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855589' -- 1010190048
select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855590' -- 1120126803
select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855591' -- 1120167925
select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '00855592' -- 1060011992

select top 10 * from SGA.dbo.Operacion where NumComFisico = '1010190048' or NumComFisico like '%1010190048%'
select top 10 * from SGA.dbo.Operacion where NumComFisico = '1120126803' or NumComFisico like '%1120126803%'
select top 10 * from SGA.dbo.Operacion where NumComFisico = '1120167925' or NumComFisico like '%1120167925%'
select top 10 * from SGA.dbo.Operacion where NumComFisico = '1060011992' or NumComFisico like '%1060011992%'

select top 10 * from SGA.dbo.DetOper where DocRef = '888800855589' or DocRef like '%888800855589%'
select top 10 * from SGA.dbo.DetOper where DocRef = '888800855590' or DocRef like '%888800855590%'
select top 10 * from SGA.dbo.DetOper where DocRef = '888800855591' or DocRef like '%888800855591%'
select top 10 * from SGA.dbo.DetOper where DocRef = '888800855592' or DocRef like '%888800855592%'

select top 10 * from SGA.dbo.DetOper where Comprobante = '1010190048'
select top 10 * from SGA.dbo.DetOper where Comprobante = '1120126803'
select top 10 * from SGA.dbo.DetOper where Comprobante = '1120167925'
select top 10 * from SGA.dbo.DetOper where Comprobante = '1060011992'

select top 10 * from SGA.dbo.Num_fisica where num_bolfac = '1010190048'
select top 10 * from SGA.dbo.Num_fisica where num_bolfac = '1120126803'
select top 10 * from SGA.dbo.Num_fisica where num_bolfac = '1120167925'
select top 10 * from SGA.dbo.Num_fisica where num_bolfac = '1060011992' 


SELECT top 100 * from SGA.dbo.Deudas
where 
        AñoAcad = '2019' AND
        PeriAcad = '02' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        --CondDeud in (0, 9) and
        NumDI = 'A50380B'
/*

    -- A50380B -- 
    8888 02217487 
    8888 02217488
    8888 02217489
    8888 02217490
    8888 02217491
*/

select top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '8888' and NumDeud = '02217487' -- B01200598963

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200598963'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra WHERE idComprobanteElectronico = 'B01200598963'

select top 10 * from SGA.dbo.DetOper where Comprobante = 'B01200598963' -- PC01 000599120
select top 10 * from SGA.dbo.DetOper where DocRef = '888802217487'

select top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000599120'
select top 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000599120'

select top 10 * from SGA.dbo.Deudas where SeriDeud = '8888' AND NumDeud = '02217487' 


select top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '001190301'

select top 10 * from SGA.dbo.DetOper where SeriOper = '0002' and NumOper = '001190301'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'BB1000262840'
select top 10 * from SGA.dbo.Control_EnvioElect where cSerie+cNumero = 'BB1000262840'


select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico like 'BA%'
select top 10 * from SGA.dbo.Notas_Cred_Deb where Tip_Nota <> 'ND'

select top 10 * from SGA.dbo.TipoDocOper 


-- SELECT tp.id AS id_principal, COUNT(tr.id_referencia) AS cantidad_referencias
-- FROM tabla_principal tp
-- LEFT JOIN tabla_referencias tr ON tp.id = tr.id_principal
-- GROUP BY tp.id
-- HAVING COUNT(tr.id_referencia) > 1;

SELECT pc.Comprobante AS id_principal, COUNT(deu.NumDeud) AS cantidad_referencias
FROM SGA.dbo.PensionesxCobrar pc
LEFT JOIN SGa.dbo.Deudas deu ON pc.SeriDeud = deu.SeriDeud AND pc.NumDeud = deu.NumDeud
--WHERE tp.Comprobante like 'B%'
where deu.CondDeud in ('0', '9')
GROUP BY pc.Comprobante
HAVING COUNT(deu.NumDeud) > 2;

SELECT pc.Comprobante AS id_principal, COUNT(do.NumOper) AS cantidad_referencias
FROM SGA.dbo.PensionesxCobrar pc
LEFT JOIN SGa.dbo.DetOper do ON pc.Comprobante = do.Comprobante
--WHERE tp.Comprobante like 'B%'
GROUP BY pc.Comprobante
HAVING COUNT(do.NumOper) > 1;



SELECT top 10 * from SGA.dbo.Deudas where SeriDeud = '8888' and NumDeud = '02369278'
SELECT top 10 * from SGA.dbo.PensionesxCobrar where Comprobante = '1060035864'

-- select top 10 * from SGA.dbo.Operacion WHERE NumComFisico = '1060035864'
SELECT top 10 * from SGA.dbo.DetOper where DocRef = '888800888696' -- 0805 000040922
select * from SGA.dbo.DetOper where SeriOper = '0805' and NumOper = '000040922'


SELECT top 10 * from SGA.dbo.Operacion where Serie_FE+Numero_FE = 'B01200722370'

select top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '001628629'
select top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000722550'


SELECT top 10 * from SGA.dbo.DetOper where Comprobante = 'B01200722370'


select top 10 * from SGA.dbo.DetOper

/* Comparacion */

select top 10 * from SGA.dbo.CondDeud

/* f10102e */
SELECT top 100 * from SGA.dbo.Deudas
where 
        AñoAcad = '2018' AND
        PeriAcad = '01' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        --CondDeud in (0, 9) and
        NumDI = 'f10102e'

select top 10 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '01668228' -- B01200267233

SELECT top 10 * from SGA.dbo.Operacion where SeriOper = '0002' and NumOper = '001075903'
SELECT top 10 * from SGA.dbo.DetOper where SeriOper = '0002' and NumOper = '001075903'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200267233'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200267233'




/* J03932K */
SELECT top 100 * from SGA.dbo.Deudas
where 
        AñoAcad = '2022' AND
        PeriAcad = '02' AND
        NumCuota in ('01', '02', '03', '04', '05') AND
        CondDeud in (0, 9) and
        NumDI = 'J03932K'


select top 10 * from SGA.dbo.PensionesxCobrar WHERE SeriDeud = '8888' and NumDeud = '02736461' --- B01200919841

--SELECT top 10 * from SGA.dbo.Operacion where Serie_FE+Numero_FE = 'B01200919841'

SELECT top 10 * from SGA.dbo.Operacion where SeriOper = 'PC01' and NumOper = '000920026'
SELECT top 10 * from SGA.dbo.DetOper where SeriOper = 'PC01' and NumOper = '000920026'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200919841'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200919841'



/* 
    1060232208 --> 4
    1110074881 --> 5
    1010148910 --> 4
    1010148911 --> 4 
*/
select top 10 * from SGA.dbo.PensionesxCobrar
where Comprobante = '1060232208'

select top 10 * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '00951110'
select top 10 * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '00951111'
select top 10 * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '01061244'
select top 10 * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '01061245'


select top 10 * from DetOper where Comprobante = '1060232208'

select top 1000 * from SGA.dbo.DetOper WHERE Comprobante like 'B%' or Comprobante like 'F%'










 

