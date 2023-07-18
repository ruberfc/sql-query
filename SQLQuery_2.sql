use SGA;

select
    cli.Cli_DNI,
    cli.Cli_Paterno + ' ' + cli.Cli_Materno + ' ' +cli.Cli_Materno as 'Nombre Completo',
    deu.NumDI,
    o.Observac,
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
from dbo.Deudas deu
inner join dbo.Operacion o on deu.NumDI = o.NumDI
inner join dbo.Clientes cli on deu.NumDI = cli.Cli_NumDoc
-- inner join dbo.PlanContab plc on deu.CodContab = plc.c_cuen
where deu.NumDI = 'f10102e' and 
deu.CondDeud in (0,9) and 
(deu.AñoAcad between '2013' and '2022')
-- AND plc.l_cuen LIKE '%PENSION%';
;

SELECT * FROM Deudas deu 
INNER JOIN PlanContab plc ON deu.CodContab=plc.c_cuen
WHERE deu.CondDeud IN (0,9) AND plc.l_cuen LIKE '%PENSION%' AND deu.[AñoAcad] BETWEEN '2013' AND '2022' and deu.NumDI = 'A621524';

SELECT * FROM Deudas deu 
INNER JOIN PlanContab plc ON deu.CodContab=plc.c_cuen
WHERE deu.CondDeud IN (0,9) AND 
(deu.[AñoAcad] BETWEEN '2013' AND '2022') AND 
--plc.l_cuen like '%PENSION%' AND
deu.NumDI = 'f10102e';

SELECT * FROM dbo.PlanContab;
SELECT * FROM dbo.CondDeud;
SELECT top 10 * FROM dbo.Deudas;


