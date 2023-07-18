
select top 10 
    Est_Id, 
    Est_NumDoc, 
    Est_Paterno + ' ' + Est_Materno +' '+ Est_Nombre 
from DBCampusNet.dbo.Est_Estudiante as est
Where est.Est_NumDoc = '10065825';

select top 10 
    Cli_NumDoc, 
    Cli_DNI, 
    Cli_Paterno + ' ' + Cli_Materno + ' ' +Cli_Nombre  
    from SGA.dbo.Clientes as cli
where cli.Cli_NumDoc = '10065825' or cli.Cli_DNI = '10065825';

select 
	 est.Est_Id,
	 est.Est_NumDoc,
	 cli.Cli_NumDoc,
	 cli.Cli_DNI
from DBCampusNet.dbo.Est_Estudiante  as est 
inner join SGA.dbo.Clientes as cli on  est.Est_NumDoc COLLATE Modern_Spanish_CI_AS = cli.Cli_DNI COLLATE Modern_Spanish_CI_AS
Where est.Est_Id = 'A621524';


declare @totalNotasCurso int
declare @totalCursosMatriculados int

select @totalNotasCurso = count(Nta_Promedio), @totalCursosMatriculados = count(Asi_Id)  from DbCampusNet.dbo.Nta_Nota 
where Mtr_Anio = '2015' and
Mtr_Periodo = 1 and 
Nta_Promedio = 'im' and
--Nta_Seccion in ('I', 'E', 'S') and 
Est_Id = 'A621524'

if @totalNotasCurso = 0 and @totalCursosMatriculados = 0
	print 'No existe registro alguno'
else
	if @totalNotasCurso = @totalCursosMatriculados
		print 'Los cursos impedidos son iguales a los cursos matriculados'
	else
		print 'algo fallo';


select
    cli.Cli_DNI,
    cli.Cli_Paterno + ' ' + cli.Cli_Materno + ' ' +cli.Cli_Materno as 'Nombre Completo',
    deu.NumDI,
    op.Observac,
    deu.CondDeud,
    case
        when deu.CondDeud =  0 then 'Normal'
        when deu.CondDeud =  1 then 'Cancelado'
        when deu.CondDeud =  2 then 'Condonado'
        when deu.CondDeud =  3 then 'Eliminado'
        when deu.CondDeud =  4 then 'Recuperado'
        when deu.CondDeud =  5 then 'Pago con Dscto'
        when deu.CondDeud =  6 then 'Fraccionado'
        when deu.CondDeud =  7 then 'Suspendido'
        when deu.CondDeud =  8 then 'p'
        when deu.CondDeud =  9 then 'Pago en BANCO'
        else ''
    end as 'Condicion de deuda'

from SGA.dbo.Deudas deu
inner join SGA.dbo.Operacion op on deu.NumDI = op.NumDI
inner join SGA.dbo.Clientes cli on deu.NumDI = cli.Cli_NumDoc
where deu.NumDI = 'f10102e' and 
deu.CondDeud in (0,9) and 
deu.AñoAcad between '2013' and '2020';





