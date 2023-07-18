
Use SGA;

--
select 
    top 100
    idComprobante,
    idComprobanteElectronico,
    IdDocumento,
    RNroDocumento
from dbo.Comprobantes_Mestra;


-- 
select
    cli.Cli_DNI,
    cli.Cli_Paterno + ' ' + cli.Cli_Materno + ' ' +cli.Cli_Materno as 'Nombre Completo',
    deu.NumDI,
    op.Observac,
    deu.CondDeud,
    deu.[AñoAcad],
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
inner join dbo.Operacion op on deu.NumDI = op.NumDI
inner join dbo.Clientes cli on deu.NumDI = cli.Cli_NumDoc
where deu.NumDI = 'f10102e' and 
deu.CondDeud in (1) and 
deu.AñoAcad between '2013' and '2020';

select
    cli.Cli_DNI,
    cli.Cli_Paterno + ' ' + cli.Cli_Materno + ' ' +cli.Cli_Materno as 'Nombre Completo',
    deu.NumDI,
    op.Observac,
    deu.CondDeud,
    deu.[AñoAcad],
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
    end as 'Condicion de deuda',
    cd.DesCondDeud

from dbo.Deudas deu
inner join dbo.Operacion op on deu.NumDI = op.NumDI
inner join dbo.Clientes cli on deu.NumDI = cli.Cli_NumDoc
inner join dbo.CondDeud cd on deu.CondDeud = cd.CondDeud
where deu.NumDI = 'f10102e' and 
deu.CondDeud in ('0', '9') and 
deu.AñoAcad between '2013' and '2020';

SELECT top 1 * from dbo.Deudas
select * from CondDeud



select * from dbo.TipOper; -- T. Independidnte
select * from dbo.TipCliente; -- T. Independiente
select * from dbo.TipDcto; -- T. Independidnte
select * from dbo.TipoDocOper; -- T. Independiente para facturacion con el campo codigo
select * from dbo.FE_TipoDocumento; -- T. Independidnte, Para facturacion
select * from dbo.CondDeud; -- T. Independidnte
select * from dbo.FE_TipoComprobante; -- T. Independidnte, Comprobantes de facturacion electronica
select * from dbo.TipCliente; -- T. Independiente
select * from dbo.CondCliente; -- T. Independiente 
select * from dbo.TDo_TipDocumento -- T. Independidnte



select top 10 * from dbo.Clientes;

select top 100 * from dbo.Num_fisica;
select top 100 * from dbo.NumeracionFE;


select distinct TipoComp from dbo.DetOper;
select distinct TIPDOC_REF from dbo.DetOper;

select distinct TipDoc  from dbo.Operacion;
select distinct NumComFisico  from dbo.Operacion;

select
    c.Cli_DNI,
    C.Cli_Paterno + ' '+ c.Cli_Materno + ' '+ c.Cli_Nombre,
    o.NumDI,
    tdo.l_tipdoc,
    o.Serie_FE,
    o.Numero_FE,
    o.NumComFisico,
    o.Observac,
    o.Tip_DocumentoTrib,
    o.Declarado_Sunat,
    do.[AñoAcad]
from dbo.Operacion o
inner join dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join dbo.Clientes c on c.Cli_NumDoc = o.NumDI
INNER JOIN dbo.TipoDocOper tdo on o.TipDoc = tdo.c_tipdoc
--INNER JOIN dbo.NumeracionFE nfe on do.
where c.Cli_NumDoc = 'f10102e' and 
do.[AñoAcad] = '2018';

--
select top 10 * from Operacion o
inner join DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join NumeracionFE ne on ne.serie = o.SeriOper
where do.Comprobante like 'b010%';

select
    distinct do.TipoComp
from dbo.Operacion o
inner join dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join dbo.Clientes c on c.Cli_NumDoc = o.NumDI
INNER JOIN dbo.TipoDocOper tdo on o.TipDoc = tdo.c_tipdoc
--INNER JOIN dbo.NumeracionFE nfe on do.
where c.Cli_NumDoc = 'f10102e' and 
do.[AñoAcad] = '2018';

SELECT * FROM dbo.TipoDocOper WHERE Codigo in (1,3,7,8);
select distinct DocCanc from dbo.Deudas;

-- 
select
    c.Cli_DNI,
    C.Cli_Paterno + ' '+ c.Cli_Materno + ' '+ c.Cli_Nombre,
    o.NumDI,
    tdo.l_tipdoc,
    o.Serie_FE,
    o.Numero_FE,
    o.NumComFisico,
    o.Observac,
    o.Tip_DocumentoTrib,
    o.Declarado_Sunat,
    do.[AñoAcad] 
from dbo.Operacion o
inner join dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join dbo.Clientes c on c.Cli_NumDoc = o.NumDI
INNER JOIN dbo.TipoDocOper tdo on o.TipDoc = tdo.c_tipdoc
--INNER JOIN dbo.NumeracionFE nfe on do.
where c.Cli_NumDoc = 'f10102e' and 
do.[AñoAcad] = '2018';

select top 10 * from dbo.NumeracionFE
select top 10 * from dbo.Operacion
select top 10 * from dbo.DetOper where DocRef <> ''
select top 10 * from dbo.Deudas 
select distinct SeriDeud from dbo.Deudas 

select top 100 * from dbo.Deudas deu 
inner join dbo.Usuarios u on u.Serie = deu.SeriDeud
where u.Serie = '8888';

select top 10 * from dbo.Usuarios;


--
select
    c.Cli_DNI,
    C.Cli_Paterno + ' '+ c.Cli_Materno + ' '+ c.Cli_Nombre,
    o.NumDI,
    nfe.SerieElec,
    nfe.NumeroElec,
    do.[AñoAcad],
    o.Serie_FE,
    o.Numero_FE
from Operacion o
inner join DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join dbo.Clientes c on c.Cli_NumDoc = o.NumDI
inner join dbo.NumeracionFE nfe on nfe.serie = o.SeriOper AND
--inner join dbo.Deudas deu on 

--do.Comprobante like 'b010%' AND
c.Cli_NumDoc = 'f10102e' AND
do.[AñoAcad] = '2017'


GO;
-- Insertar nota de credito
CREATE PROC SP_INSERT_NOTAS_CREDITO
    @SeriOper CHAR(4),
    @NumOper CHAR(9),
   -- @Fecha_Emision, DATE,
    @Serie_Nota CHAR(4),
    @Numero_Nota CHAR(8),
    @Motivo VARCHAR(200),
    @Importe_Total DECIMAL(18,2),
    @Tip_Nota VARCHAR(2),
    @Cod_NotaCredDeb CHAR(2),
    @Item CHAR(3),
    @SeriOpRef CHAR(4),
    @NumOpRef CHAR(9)
AS
    INSERT INTO dbo.Notas_Cred_Deb (SeriOper, NumOper, Fecha_Emision, Serie_Nota, Numero_Nota, Motivo, Importe_Total, Tip_Nota, Cod_NotaCredDeb, Item, SeriOpRef, NumOpRef)
    VALUES (@SeriOper, @NumOper, CONVERT (date, GETDATE()), @Serie_Nota, @Numero_Nota, @Motivo, @Importe_Total, @Tip_Nota, @Cod_NotaCredDeb, @Item, @SeriOpRef, @NumOpRef);


GO;
-- Funcion para obtener ultimo Nota Credito
CREATE FUNCTION ObnerUltimoValorNotaCreditoPorUsuario
 (
    @SeriOper CHAR(4) = '8888',
    @Numero_Nota_Max CHAR(8)
 )
  returns CHAR(8)
  begin
   SELECT @Numero_Nota_Max = MAX(Numero_Nota) FROM dbo.Notas_Cred_Deb WHERE SeriOper = @SeriOper
   return @Numero_Nota_Max
  end;

GO;
-- Funcion para obtener el maximo registro de NumOper en la tabla Operacion
CREATE FUNCTION MaxNumOperOperacionPorUsuario
 (
    @SeriOper CHAR(4) = '8888',
    @NumOper_Max CHAR(8)
 )
  returns CHAR(8)
  begin
   SELECT @NumOper_Max = MAX(NumOper) FROM dbo.Operacion WHERE SeriOper = @SeriOper
   return @NumOper_Max
  end;

GO;

SELECT MAX(NumOper) FROM dbo.Operacion 
WHERE SeriOper = '8888';
SELECT MAX(NumOper) FROM dbo.DetOper
WHERE SeriOper = '8888';
SELECT MAX(NumDeud) FROM dbo.Deudas
WHERE SeriDeud = '8888';

SELECT top 10 * from dbo.Deudas where NumDI = 'f10102e'
SELECT top 10 * from dbo.Operacion;

SELECT MIN(NumOper) FROM dbo.Operacion 
WHERE SeriOper = '8888';



SELECT TOP 10 * FROM dbo.Notas_Cred_Deb
WHERE
Fecha_Emision BETWEEN '2022-01-01' and '2022-12-30';

SELECT TOP 10 * FROM dbo.Operacion;

Select top 10 * from dbo.Operacion o
INNER JOIN dbo.Deudas deu on o.SeriOper = deu.SeriDeud and o.NumOper = deu.NumDeud

Select top 10 * from dbo.DetOper do
INNER JOIN dbo.Deudas deu on do.SeriOper = deu.SeriDeud and do.NumOper = deu.NumDeud


-- Deudas Cliente
DECLARE @numdi varchar(15) = 'f10102e'
BEGIN
if @numdi like 'EA%'
    SELECT 
        deu.SeriDeud,
        deu.NumDeud,
        RTRIM(plc.c_cuen) codi,
        CASE deu.Numcuota 
            WHEN '  ' THEN '' 
            ELSE 'CUOTA ' + LTRIM(deu.NumCuota+' ') 
        END + RIGHT(deu.[AñoAcad],2) + RIGHT(deu.PeriAcad,1) + ' ' + RTRIM(plc.l_cuen) as Desi,
        deu.TipMoneda,
        tm.AbrMoneda nom,
        deu.Importe,
        case 
            when deu.FecVenc < getdate() and deu.TasaMora > 0 
		        then convert(decimal(19,2), ROUND( (deu.TasaMora * (deu.importe + (isnull(deu.Valor,0))) * (datediff(day,deu.FecVenc,getdate())) ),2)) 
            else 0.00 
        end mora,
        CONVERT(VARCHAR(11),deu.FecVenc,104) fecvenc,
        deu.Observac,
        case 
            when deu.TasaMora > 0 then (
                case c.sed_id 
                    when 'LI' then '7057044' 
                    else '7044063' 
                end)
            else '' 
        end dMora,
        deu.[AñoAcad],
        deu.PeriAcad,
        deu.NumCuota, 
        deu.CondDeud

    FROM dbo.clientes c
    INNER JOIN dbo.Deudas deu ON c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc ON deu.CodContab = plc.c_cuen
    INNER JOIN dbo.TipMoneda tm ON deu.TipMoneda = tm.TipMoneda
    WHERE 
        (deu.CondDeud = '0' OR deu.CondDeud = '9') AND
        c.Cli_NumDoc = @numdi
    ORDER BY
        deu.[AñoAcad], deu.PeriAcad, deu.NumCuota    

Else
    /*
	select b.SeriDeud,b.NumDeud,rtrim(c.c_cuen)codi,
	CASE b.Numcuota WHEN '  ' THEN '' ELSE 'CUOTA '+LTRIM(b.numcuota+' ') END+RIGHT(b.añoacad,2)+RIGHT(b.periacad,1)+' '+RTRIM(c.l_cuen)as Desi,    
    b.tipmoneda,d.AbrMoneda mon,importe,
    case when FecVenc<getdate() 
		then CONVERT(decimal(15,2),ROUND(((importe+(isnull(valor,0)))*tasamora*(datediff(day,FecVenc,getdate()))),2)) else 0.00 end mora,
    CONVERT(VARCHAR(11),FecVenc,104) fecvenc,b.Observac,
    case when tasamora>0 then (case a.sed_id when 'LI' then '7057044' else '7044063' end)else '' end dMora,
    AñoAcad,PeriAcad,NumCuota, b.CondDeud
	from Clientes a inner join Deudas b on a.Cli_NumDoc=b.numdi 
	inner join PlanContab c on b.CodContab =c.c_cuen 
	inner join TipMoneda d on b.TipMoneda=d.TipMoneda     
	where (b.CondDeud='0' or b.CondDeud='9') and a.Cli_NumDoc=@numdi
	order by añoacad,periacad,numcuota
    */

    Select 
        deu.SeriDeud,
        deu.NumDeud,
        RTRIM(plc.c_cuen) 'Codigo Contable',
        CASE  deu.NumCuota 
            WHEN '  ' THEN '' 
            ELSE 'CUOTA ' +LTRIM(deu.NumCuota+' ') 
        END + RIGHT(deu.[AñoAcad],2) + RIGHT(deu.PeriAcad,1) +' '+ RTRIM(plc.l_cuen) as Desi,
        deu.TipMoneda,
        tm.AbrMoneda mon,
        deu.Importe,
        case 
            when  deu.FecVenc < getdate() 
		        then CONVERT(decimal(15,2), ROUND(( (deu.Importe+(isnull( deu.Valor,0))) * deu.TasaMora * (datediff(day,deu.FecVenc,getdate())) ),2)) 
            else 0.00 
        end mora,
        CONVERT(VARCHAR(11), deu.FecVenc,104) fecvenc,
        deu.Observac,
        case 
            when deu.TasaMora > 0 then (
                case c.sed_id 
                    when 'LI' then '7057044' 
                    else '7044063' 
                end)
            else '' 
        end dMora,
        deu.[AñoAcad],
        deu.PeriAcad,
        deu.NumCuota,
        deu.CondDeud
    from dbo.Clientes c 
    INNER JOIN dbo.Deudas deu on c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    INNER JOIN dbo.TipMoneda tm on deu.TipMoneda = tm.TipMoneda
    WHERE 
        (deu.CondDeud = '0' or deu.CondDeud = '9') AND
        c.Cli_NumDoc = @numdi
    ORDER BY deu.[AñoAcad], deu.PeriAcad, deu.NumCuota
END;

-- exec sc_DeudasClientes 'A83357E'

select top 10 * 
from Operacion o
inner join dbo.DetOper do on o.SeriOper = do.SeriOper and o.NumOper = do.NumOper
inner join dbo.NumeracionFE ne on ne.serie = o.SeriOper
--INNER JOIN dbo.Clientes
where do.Comprobante like 'b010%';


-- Deuda solo pensiones con NumCuota in (01, 02, 03, 04, 05)
DECLARE @num_di varchar(15) = 'E03585K'
BEGIN
if @num_di like 'EA%'
    SELECT 
        deu.SeriDeud,
        deu.NumDeud,
        RTRIM(plc.c_cuen) codi,
        CASE deu.Numcuota 
            WHEN '  ' THEN '' 
            ELSE 'CUOTA ' + LTRIM(deu.NumCuota+' ') 
        END + RIGHT(deu.[AñoAcad],2) + RIGHT(deu.PeriAcad,1) + ' ' + RTRIM(plc.l_cuen) as Desi,
        deu.TipMoneda,
        tm.AbrMoneda nom,
        deu.Importe,
        case 
            when deu.FecVenc < getdate() and deu.TasaMora > 0 
		        then convert(decimal(19,2), ROUND( (deu.TasaMora * (deu.importe + (isnull(deu.Valor,0))) * (datediff(day,deu.FecVenc,getdate())) ),2)) 
            else 0.00 
        end mora,
        CONVERT(VARCHAR(11),deu.FecVenc,104) fecvenc,
        deu.Observac,
        case 
            when deu.TasaMora > 0 then (
                case c.sed_id 
                    when 'LI' then '7057044' 
                    else '7044063' 
                end)
            else '' 
        end dMora,
        deu.[AñoAcad],
        deu.PeriAcad,
        deu.NumCuota, 
        deu.CondDeud
    FROM dbo.clientes c
    INNER JOIN dbo.Deudas deu ON c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc ON deu.CodContab = plc.c_cuen
    INNER JOIN dbo.TipMoneda tm ON deu.TipMoneda = tm.TipMoneda
    WHERE 
        (deu.CondDeud = '0' OR deu.CondDeud = '9') AND
        c.Cli_NumDoc = @num_di AND
        deu.NumCuota in (01, 02, 03, 04, 05)
    ORDER BY
        deu.[AñoAcad], deu.PeriAcad, deu.NumCuota    

Else
    Select 
        deu.SeriDeud,
        deu.NumDeud,
        RTRIM(plc.c_cuen) 'Codigo Contable',
        CASE  deu.NumCuota 
            WHEN '  ' THEN '' 
            ELSE 'CUOTA ' +LTRIM(deu.NumCuota+' ') 
        END + RIGHT(deu.[AñoAcad],2) + RIGHT(deu.PeriAcad,1) +' '+ RTRIM(plc.l_cuen) as Desi,
        deu.TipMoneda,
        tm.AbrMoneda mon,
        deu.Importe,
        case 
            when  deu.FecVenc < getdate() 
		        then CONVERT(decimal(15,2), ROUND(( (deu.Importe+(isnull( deu.Valor,0))) * deu.TasaMora * (datediff(day,deu.FecVenc,getdate())) ),2)) 
            else 0.00 
        end mora,
        CONVERT(VARCHAR(11), deu.FecVenc,104) fecvenc,
        deu.Observac,
        case 
            when deu.TasaMora > 0 then (
                case c.sed_id 
                    when 'LI' then '7057044' 
                    else '7044063' 
                end)
            else '' 
        end dMora,
        deu.[AñoAcad],
        deu.PeriAcad,
        deu.NumCuota,
        deu.CondDeud
    from dbo.Clientes c 
    INNER JOIN dbo.Deudas deu on c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    INNER JOIN dbo.TipMoneda tm on deu.TipMoneda = tm.TipMoneda
    WHERE 
        (deu.CondDeud = '0' or deu.CondDeud = '9') AND
        c.Cli_NumDoc = @num_di AND
        deu.NumCuota in (01, 02, 03, 04, 05)
    ORDER BY deu.[AñoAcad], deu.PeriAcad, deu.NumCuota
END;

--
DECLARE @CodeEst varchar(15) = 'E03585K'
BEGIN
if @CodeEst like 'EA%'
    SELECT 
        RTRIM(plc.c_cuen) codi
    FROM dbo.clientes c
    INNER JOIN dbo.Deudas deu ON c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc ON deu.CodContab = plc.c_cuen
    WHERE 
        (deu.CondDeud = '0' OR deu.CondDeud = '9') AND
        c.Cli_NumDoc = @CodeEst AND
        deu.NumCuota in (01, 02, 03, 04, 05)   
Else
    Select 
        RTRIM(plc.c_cuen) 'Codigo Contable'
    from dbo.Clientes c 
    INNER JOIN dbo.Deudas deu on c.Cli_NumDoc = deu.NumDI
    INNER JOIN dbo.PlanContab plc on deu.CodContab = plc.c_cuen
    WHERE 
        (deu.CondDeud = '0' or deu.CondDeud = '9') AND
        c.Cli_NumDoc = @CodeEst AND
        deu.NumCuota in (01, 02, 03, 04, 05)
END;

select * from dbo.CondDeud
select top 100 * from dbo.Deudas
select top 10 * from dbo.Descuento_doble
where Seriedeud like 'B%'

select top 100 * from dbo.DetOper
select top 100 * from dbo.Operacion

SELECT * FROM dbo.Deudas deu 
INNER JOIN PlanContab plc ON deu.CodContab=plc.c_cuen
WHERE 
deu.CondDeud IN (0,9) AND 
--(plc.l_cuen LIKE '%PENSION%' OR plc.l_cuen LIKE 'PENSION%' OR plc.l_cuen LIKE '%PENSION') AND
(deu.[AñoAcad] BETWEEN '2015' AND '2022') AND
deu.NumCuota in (01, 02, 03, 04, 05) AND
deu.NumDI = 'J03932K'


select * from dbo.PlanContab WHERE l_cuen like '%PENSION%'
select distinct NumCuota from dbo.Deudas
select CONVERT(VARCHAR(11),GETDATE(),104);

use SGA



select distinct dif from dbo.NumeracionFE
select top 10 * from dbo.NumeracionFE
select * from TipoDocOper




