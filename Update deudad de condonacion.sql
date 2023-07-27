-- deudas de estudiante
select * from SGA.dbo.Deudas deu 
where   deu.[AñoAcad] = '2015' AND
        deu.PeriAcad = '02' AND
        deu.NumCuota = '04' AND
        deu.CondDeud in (0,9) AND
        deu.NumDI = 'A621524'

GO

CREATE PROCEDURE SP_UPDATE_DEUDA_CONDONADO(
    @codigo_est varchar(15),
    @anio_acad char(4),
    @periodo_acad varchar(2),
    @num_cuota char(2)
)
AS BEGIN

    -- total notas curso
    DECLARE @TotalNotasCurso int;
    -- Total cursos matriculados
    DECLARE @TotalCursosMatriculados int;


    SELECT @TotalNotasCurso = count(Nta_Promedio), @TotalCursosMatriculados = count(Asi_Id)
    FROM DBCampusNet.dbo.Nta_Nota
    WHERE Mtr_Anio = @anio_acad AND
        Mtr_Periodo = @periodo_acad AND
        Nta_Promedio = 'im' AND
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

            -- serie y numeracion deuda
            DECLARE @SerieDeuda char(4), @NumeracionDeuda char(8)
            select @SerieDeuda = SeriDeud, @NumeracionDeuda = NumDeud 
            from SGA.dbo.Deudas 
            where   [AñoAcad] = @anio_acad AND
                    PeriAcad = @DeudaPeriodoA AND
                    NumCuota = @DeudaNumCuota AND
                    CondDeud in (0,9) AND
                    NumDI = @codigo_est;

            -- IF EXISTS (SELECT * from SGA.dbo.Comprobantes_Mestra where  idComprobante = @SerieDeuda+@NumeracionDeuda) BEGIN
            IF EXISTS (SELECT * from SGA.dbo.PensionesxCobrar where SeriDeud = TRIM(@SerieDeuda) and NumDeud = TRIM(@NumeracionDeuda) and Comprobante LIKE 'B%') BEGIN

                DECLARE @ComprobanteFE varchar(15);
                SELECT TOP 1 @ComprobanteFE = Comprobante from SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@SerieDeuda) AND NumDeud = TRIM(@NumeracionDeuda);

                DECLARE @SerieOperFE CHAR(4), @NumOperFE CHAR(9);
                SELECT @SerieOperFE = SeriOper, @NumOperFE = NumOper from SGA.dbo.Operacion where Serie_FE+Numero_FE = TRIM(@ComprobanteFE);

                Update SGA.dbo.Deudas SET CondDeud = '2', Observac = 'CONDONACIÓN DEUDA ',  DocCanc = @SerieOperFE+@NumOperFE, actualiza = ISNULL(actualiza, 0) + 1
                WHERE   [AñoAcad] = @anio_acad AND
                        PeriAcad = @DeudaPeriodoA AND
                        NumCuota = @DeudaNumCuota AND
                        CondDeud in (0,9) AND
                        NumDI = @codigo_est;

                DELETE FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = @SerieDeuda AND NumDeud = @NumeracionDeuda

            END
            ELSE BEGIN

                DECLARE @Comprobante varchar(15);
                SELECT TOP 1 @Comprobante = Comprobante from SGA.dbo.PensionesxCobrar WHERE SeriDeud = TRIM(@SerieDeuda) AND NumDeud = TRIM(@NumeracionDeuda);

                DECLARE @SerieOper CHAR(4), @NumOper CHAR(9);
                SELECT @SerieOper = SeriOper, @NumOper = NumOper from SGA.dbo.Operacion where NumComFisico = TRIM(@Comprobante);

                Update SGA.dbo.Deudas SET CondDeud = '2', Observac = 'CONDONACIÓN DEUDA',  DocCanc = @SerieOper+@NumOper, actualiza = ISNULL(actualiza, 0) + 1
                WHERE   [AñoAcad] = @anio_acad AND
                        PeriAcad = @DeudaPeriodoA AND
                        NumCuota = @DeudaNumCuota AND
                        CondDeud in (0,9) AND
                        NumDI = @codigo_est;
                DELETE FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = @SerieDeuda AND NumDeud = @NumeracionDeuda;  
            END


            SELECT top 10 * from SGA.dbo.Num_fisica
            SELECT top 10 * from SGA.dbo.Operacion Where SeriOper = '0012' and NumOper = '000038664'

            SELECT top 10 * from SGA.dbo.TDo_TipDocumento
    

            select top 10 * from SGA.dbo.Deudas

            select top 10 * from SGA.dbo.Clientes

            select distinct actualiza from SGA.dbo.Deudas

            SELECT top 10 * from SGA.dbo.Num_fisica 
            SELECT top 10 * from SGA.dbo.Num_fisica WHERE num_bolfac ='005003002'
            
            Select top 10 * from SGA.dbo.Operacion where SeriOper = '0012'  and NumOper = '000038664'


            -- SerieOper, NumOper y DocRef
            DECLARE  @SerieOperacion char(4), @NumeracionOperacion char(9), @DocRefDetalleOper char(12)
            SELECT @SerieOperacion = SeriOper, @NumeracionOperacion = NumOper, @DocRefDetalleOper = DocRef from SGA.dbo.DetOper
            where DocRef = @SerieDeuda+@NumeracionDeuda

            -- Actulizar deuda
            Update SGA.dbo.Deudas SET CondDeud = '2', DocCanc = @SerieOperacion+@NumeracionOperacion
            WHERE   [AñoAcad] = @anio_acad AND
                    PeriAcad = @DeudaPeriodoA AND
                    NumCuota = @DeudaNumCuota AND
                    CondDeud in (0,9) AND
                    NumDI = @codigo_est

            
            DELETE FROM SGA.dbo.PensionesxCobrar WHERE SeriDeud = @SerieDeuda AND NumDeud = @NumeracionDeuda



        END
          
    END


END


-- SELECT @SerieDeuda, @NumeracionDeuda
-- SELECT @SerieOperacion, @NumeracionOperacion, @DocRefDetalleOper  


select *
from SGA.dbo.Deudas 
where   ([AñoAcad] BETWEEN '2015' AND '2022')  AND
        --PeriAcad in ('01', '02') AND
        --NumCuota in ('01', '02', '03', '03', '05') AND -- =  @DeudaNumCuota AND
        --CondDeud  in ('0', '9') AND-- in (0,9) AND
        Importe <= 104 AND
        --CondDeud  = '2' AND
        NumDI = 'M01716J'; 

SELECT * from SGA.dbo.Operacion where NumDI = 'A612668' and TotOper <= 104

SELECT * from SGA.dbo.DetOper where SeriOper = '8888' and NumOper = '000002684'

SELECT * from SGA.dbo.Operacion where NumDI = 'F06174H' and TipOper = '01'
SELECT * from SGA.dbo.DetOper where TipCodCont = 'H' and Importe < 0

SELECT * from SGA.dbo.TipOper
     

select top 10 * from CondDeud

select top 10* from SGA.dbo.Operacion

-- Eliminar el registro Pensiones por cobrar
-- IF EXISTS () BEGIN

--     SELECT top 10 * from SGA.dbo.PensionesxCobrar where SeriDeud = '' and NumDeud = ''
-- END
