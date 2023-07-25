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
            from SGA.dbo.Deudas deu 
            where   deu.[AñoAcad] = @anio_acad AND
                    deu.PeriAcad = @DeudaPeriodoA AND
                    deu.NumCuota = @DeudaNumCuota AND
                    deu.CondDeud in (0,9) AND
                    deu.NumDI = @codigo_est

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
        END
          
    END


END


-- SELECT @SerieDeuda, @NumeracionDeuda
-- SELECT @SerieOperacion, @NumeracionOperacion, @DocRefDetalleOper  
