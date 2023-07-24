

go

create procedure SP_Procesos_Condonacion(
    @codigo_est varchar(15),
    @ciclo_acad varchar(5),
    @anio_acad char(4),
    @periodo_acad varchar(2),
    @num_cuota char(2)
    --@cuota_valor numeric(18,2)
)AS
BEGIN 
    -- Var total notas curso
    DECLARE @TotalNotasCurso int;
    -- Var Total cursos matriculados
    DECLARE @TotalCursosMatriculados int;

    DECLARE @usuarioSerie char(4) = '8888';
    DECLARE @serieBoleta char(4) = 'B026';
    DECLARE @serieNotaCreito char(4) = 'BA26';

    SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE Mtr_Anio = @anio_acad AND --(Mtr_Anio BETWEEN '2015' AND '2022') AND -- Mtr_Anio = '2015' and
        Mtr_Periodo = @periodo_acad AND  -- Mtr_Periodo = 1 and -- Omitir
        Nta_Promedio = 'im' AND
        --Nta_Seccion in ('I', 'E', 'S') and 
        Est_Id = @codigo_est;  

    IF @TotalNotasCurso = 0 AND @TotalCursosMatriculados = 0 BEGIN
        RETURN 'No se encontro registro de matricula';
    END
    ELSE BEGIN
        IF @TotalNotasCurso = @TotalCursosMatriculados  AND  @TotalNotasCurso > 0 AND @TotalCursosMatriculados > 0 BEGIN
            /* Impedido todos los cursos que no pago su cuota */

            -- Var deuda periodo agregar un cero delante
            DECLARE @DeudaPeriodoA char(2);
            SET @DeudaPeriodoA = CONCAT('0', @periodo_acad);

            -- Var deuda numero cuota agregar un cero delante
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

                 -- Var incremento numeracion_operacion
                DECLARE @NumOper INT;
                SELECT @NumOper = CONVERT(INT, NumOper) FROM SGA.dbo.Usuarios WHERE Serie = @usuarioSerie;
                SET @NumOper = @NumOper + 1;   

                 -- Var conversion a char numeracion_operacion
                DECLARE @NumOperChar CHAR(9);
                SET @NumOperChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @NumOperChar ))), 9);

                 -- Var especialidad estudiante
                DECLARE @CodEspEst VARCHAR(4);
                SELECT top 1 @CodEspEst = CodEspe FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Var Sede estudio estudiante
                DECLARE @SedeEst VARCHAR(2);
                SELECT @SedeEst = Sed_Id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Var Programa  de modalidad academica
                DECLARE @Programa char(2);
                SELECT top 1 @Programa = MAC_id FROM SGA.dbo.Clientes WHERE Cli_NumDoc = @codigo_est;

                -- Var numeracion_boleta
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

                -- Var serie, numeracion, codContab deuda
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

                -- Var 
                DECLARE @NewNumBoleta INT, @NewNumBoletaChar char(9);
                SET @NewNumBoleta = CAST(@NumBoletaChar AS INT) + 1;
                SET @NewNumBoletaChar = RIGHT('000000000' + LTRIM(RTRIM(CONVERT(CHAR(9), @NewNumBoleta ))), 9);

                UPDATE SGA.dbo.NumeracionFE SET NumeroElec = @NewNumBoletaChar WHERE serie = @usuarioSerie AND SerieElec = @serieBoleta

                UPDATE SGA.dbo.Usuarios SET NumOper = @NumOperChar WHERE Serie = @usuarioSerie;

                
                
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
    DECLARE @TotalNotasCurso int;
    -- Var Total cursos matriculados
    DECLARE @TotalCursosMatriculados int;        

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


select * from SGA.dbo.Deudas deu 
INNER JOIN Comprobantes_Mestra cm on deu.SeriDeud+deu.NumDeud = cm.idComprobante
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
select  distinct MAC_id from clientes
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





        
        

        




               

