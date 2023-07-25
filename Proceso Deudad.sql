
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
           
            -- Periodo agregar un cero delante
            DECLARE @DeudaPeriodoA char(2);
            SET @DeudaPeriodoA = CONCAT('0', @periodo_acad);

            -- Numero cuota agregar un cero delante
            DECLARE @DeudaNumCuota char(2);
            SET @DeudaNumCuota = CONCAT('0', @num_cuota);

            -- Serie y Numeracion de Deuda
            DECLARE @DeudaSerie char(4), @DeudaNumeracion char(8), @DeudaCodContab char(14);

            SELECT @DeudaSerie = SeriDeud, @DeudaNumeracion = NumDeud from SGA.dbo.Deudas
            where   AñoAcad = @anio_acad AND
                    PeriAcad = @DeudaPeriodoA AND
                    NumCuota = @DeudaNumCuota AND -- in ('01', '02', '03', '04', '05') AND
                    CondDeud in (0, 9) and
                    NumDI = @codigo_est

            IF EXISTS(SELECT * from SGA.dbo.Comprobantes_Mestra where  idComprobante = @DeudaSerie+@DeudaNumeracion) BEGIN

                

                -- Serie y Numeracion Operacion
                DECLARE @IdComprobanteElectronico VARCHAR(20);
                DECLARE @OperSerie char(4), @OperNumeracion char(9);
                DECLARE @OperSerie_FE char(4), @OperNumeracion_FE CHAR(8)

                SELECT  @IdComprobanteElectronico = idComprobanteElectronico FROM SGA.dbo.Comprobantes_Mestra where idComprobante = @DeudaSerie+@DeudaNumeracion
                SELECT  @OperSerie = SeriOper, @OperNumeracion = NumOper, @OperSerie_FE = Serie_FE, @OperNumeracion_FE = Numero_FE from SGA.dbo.Operacion where Serie_FE+Numero_FE =  @IdComprobanteElectronico
                


                
                

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



                

            END
            ELSE BEGIN
                
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

                select distinct TIPDOC_REF from SGA.dbo.DetOper do 
                inner JOIN SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
                where o.NumDI = 'f10102e'

                select * from SGA.dbo.TipoDocOper

                select top 100 * from SGA.dbo.DetOper do 
                inner JOIN SGA.dbo.Operacion o on do.SeriOper = o.SeriOper and do.NumOper = o.NumOper
                where o.NumDI = 'f10102e' and do.AñoAcad = 2018

                select top 100 * from SGA.dbo.TipDcto
                select top 100 * from SGA.dbo.TipoDocOper

                SELECT CONVERT(smalldatetime, GETDATE(), 120)

            END

        END
        ELSE BEGIN
            RETURN 'No se hiso impedir en todos los cursos'
        END
        
    END
END



