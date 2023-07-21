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

select top 10 --*
    pfe.idComprobanteElectronico,
    pfe.idComprobante,
    do.SeriOper,
    do.NumOper,
    --do.DocRef,
    -- do.Comprobante_REF,
    -- do.TIPDOC_REF,
    do.Comprobante
    
from SGA.dbo.DetalleComprobante_Maestra pfe 
INNER JOIN SGA.dbo.DetOper do on pfe.idComprobante = do.SeriOper+do.NumOper
where idComprobanteElectronico = 'B00100071769'


select top 10 -- *
    pfe.idComprobanteElectronico,
    pfe.idComprobante,
    do.SeriOper,
    do.NumOper,
    --do.DocRef,
    -- do.Comprobante_REF,
    -- do.TIPDOC_REF,
    do.Comprobante,
    do.TipoComp,
    tdo.l_tipdoc,
    pfe.Descripcion,

    do.CodContab,
    plc.l_cuen
    
from SGA.dbo.DetalleComprobante_Maestra pfe 
INNER JOIN SGA.dbo.DetOper do on pfe.idComprobante = do.SeriOper+do.NumOper
INNER JOIN SGA.dbo.PlanContab plc on do.CodContab = plc.c_cuen
INNER join SGA.dbo.TipoDocOper tdo on do.TipoComp = tdo.Codigo
where idComprobanteElectronico = 'B00100071769'

-- Relacion Detalle Operacion y Deudas
select top 10 * from SGA.dbo.DetOper do
inner join SGA.dbo.Deudas deu on  do.DocRef = deu.SeriDeud + ' ' + deu.NumDeud or do.DocRef = deu.SeriDeud+deu.NumDeud

select top 10 * from SGA.dbo.DetOper do
inner join SGA.dbo.Deudas deu on  do.DocRef = deu.SeriDeud + ' ' + deu.NumDeud or do.DocRef = deu.SeriDeud+deu.NumDeud
where do.DocRef = '000 01102024'

select 
    do.SeriOper, 
    do.NumOper,
    do.DocRef,
    '' as separador,
    deu.SeriDeud,
    deu.NumDeud,
    deu.DocCanc
from SGA.dbo.DetOper do
inner join SGA.dbo.Deudas deu on  do.DocRef = deu.SeriDeud + ' ' + deu.NumDeud or do.DocRef = deu.SeriDeud+deu.NumDeud
where do.DocRef = '000 01102024'



-- Relacion Numeracion
select top 10 * from SGA.dbo.NumeracionFE where SerieElec = 'B001' and NumeroElec = '00071769';

-- Comprobantes Enviados con resultado
select top 10 * from SGA.dbo.Control_EnvioElect where cSerie = 'B001' and cNumero = '00071769'

-- Comprobantes Enviados con resultado
select top 10 *
from SGA.dbo.DetalleComprobante_Maestra 
where idComprobanteElectronico = 'B00100071769'

-- Comprobante electronico detalle 
select distinct top 10  -- *
    dcm.idComprobanteElectronico,
    dcm.idComprobante,
    dcm.Descripcion,
    -- '' separador,
    --do.SeriOper+do.NumOper Operacion,
    
    -- dcm.CodigoItem,
    dcm.Descripcion,
    -dcm.TotalVenta
    --do.Importe
    --do.item
FROM SGA.dbo.DetalleComprobante_Maestra dcm 
INNER JOIN SGA.dbo.DetOper do on dcm.idComprobante = do.SeriOper+do.NumOper
WHERE
    dcm.idComprobanteElectronico = 'B00100071769' and
    --do.SeriOper+do.NumOper='0013000465588'
    dcm.idComprobante = '0013000465588'
GROUP BY dcm.idComprobanteElectronico, dcm.idComprobante,dcm.Descripcion, do.Importe

select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'BB0100015790'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200330454'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B00100071769'

select top 10 * from SGA.dbo.Control_EnvioElect where cSerie = 'B001' and cNumero = '00071769'

SELECT top 10 * from SGA.dbo.Deudas

SELECT top 10 * from SGA.dbo.Operacion o 
INNER JOIN SGA.dbo.DetOper do on o.SeriOper = do.SeriOper AND o.NumOper = do.NumOper
WHERE o.Serie_FE = 'B001' AND o.Numero_FE = '00071769'

select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0013000465588'
select top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B00100071769'

SELECT TOP 1 car.Fac_Id FROM SGA.dbo.Car_Carrera car
INNER JOIN SGA.dbo.Operacion o on car.Fac_Id = o.programa
WHERE o.NumDI = 'f10102e';

-- En campo programa de tabla operacion tiene un registro 16 que no concuerda con ningun registro de campo Fac_Id de tabla Car_carrera
select distinct Fac_Id from Car_Carrera
SELECT distinct programa from Operacion 


select * from SGA.dbo.Usuarios where Serie = '8888'

select * from SGA.dbo.NumeracionFE where Serie = '8888'

select distinct  top 10  SerieElec from SGA.dbo.NumeracionFE where Serie = '8888'
SELECT top 10 * from SGA.dbo.Num_fisica

select distinct id from SGA.dbo.DetalleComprobante_Maestra WHERE idComprobante like '888%'
select distinct UnidadMedida from SGA.dbo.DetalleComprobante_Maestra
select distinct TipoImpuesto from SGA.dbo.DetalleComprobante_Maestra
select distinct TipoPrecio from SGA.dbo.DetalleComprobante_Maestra

select top 10 * from SGA.dbo.DetalleComprobante_Maestra 
WHERE idComprobante like '888%' and Impuesto <> 0 and TipoImpuesto = 10

select * from SGA.dbo.Deudas where AñoAcad = '2018' and NumCuota in (01, 02, 03, 04, 05) and PeriAcad = 01 and NumDI = 'f10102e'


select * from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.Operacion o on deu.DocCanc = o.SeriOper+o.NumOper
where deu.AñoAcad = '2018' and deu.NumCuota in (01, 02, 03, 04, 05) and deu.PeriAcad = 01 and deu.NumDI = 'f10102e'

select 
    deu.NumDI,
    deu.SeriDeud,
    deu.NumDeud,
    deu.NumCuota,
    deu.DocCanc,
    '' Separador,
    o.SeriOper,
    o.NumOper,
    o.Serie_FE,
    o.Numero_FE
    
from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.Operacion o on deu.DocCanc = o.SeriOper+o.NumOper
where deu.AñoAcad = '2018' and deu.NumCuota in (01, 02, 03, 04, 05) and deu.PeriAcad = 01 and deu.NumDI = 'f10102e'

select 
    deu.NumDI,
    deu.SeriDeud,
    deu.NumDeud,
    deu.NumCuota,
    deu.DocCanc,
    '' Separador,
    o.SeriOper,
    o.NumOper,
    o.Serie_FE,
    o.Numero_FE,
    '' Separador,
    cm.idComprobanteElectronico,
    cm.idComprobante,
    cm.IdDocumento
    
from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.Operacion o on deu.DocCanc = o.SeriOper+o.NumOper
INNER join SGA.dbo.Comprobantes_Mestra cm on o.Serie_FE+ o.Numero_FE = cm.idComprobanteElectronico
where deu.AñoAcad = '2018' and deu.NumCuota in (01, 02, 03, 04, 05) and deu.PeriAcad = 01 and deu.NumDI = 'f10102e'


select top 10 * from SGA.dbo.Comprobantes_Mestra 
select top 10  * from SGA.dbo.Operacion where Serie_FE <> '' or Serie_FE <> null
select top 10  * from SGA.dbo.DetOper where DocRef like '888%'
select top 10 * from SGA.dbo.Deudas

select 
    deu.NumDI,
    deu.SeriDeud,
    deu.NumDeud,
    deu.NumCuota,
    deu.DocCanc,
    '' Separador,
    o.SeriOper,
    o.NumOper,
    o.Serie_FE,
    o.Numero_FE,
    '' Separador,
    cm.idComprobanteElectronico,
    cm.idComprobante,
    cm.IdDocumento
    
from SGA.dbo.Deudas deu
INNER JOIN SGA.dbo.Operacion o on deu.DocCanc = o.SeriOper+o.NumOper
INNER join SGA.dbo.Comprobantes_Mestra cm on o.Serie_FE+ o.Numero_FE = cm.idComprobanteElectronico
where deu.AñoAcad = '2018' and deu.NumCuota in (01, 02, 03, 04, 05) and deu.PeriAcad = 01 and deu.NumDI = 'f10102e' and deu.DocCanc ='0002001098278'

/*
    Deudas Doc Ref
    - 888800237206
    - 888800237207
    - 888800237208

    Operacion
    0002 , 001075903
    0002 , 001098275
    0002 , 001098276
    0002 , 001098277
    0002 , 001098278
*/


SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0002001075903'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0002001075903'
--
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0002001098275'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0002001098275'
--
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0002001098276'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0002001098276'
--
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0002001098277'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0002001098277'
--
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0002001098278'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0002001098278'

SELECT top 10 * from SGA.dbo.Control_EnvioElect where cSerie = '' and  cNumero = ''

-- select 
--     cm.idComprobanteElectronico,
--     cm.idComprobante,
--     cm.IdDocumento
    

-- from SGA.dbo.DetOper do
-- INNER join SGA.dbo.Comprobantes_Mestra cm on o.Serie_FE+ o.Numero_FE = cm.idComprobanteElectronico
-- where deu.AñoAcad = '2018' and deu.NumCuota in (01, 02, 03, 04, 05) and deu.PeriAcad = 01 and deu.NumDI = 'f10102e' and deu.DocCanc ='0002001098278'


SELECT * from SGA.dbo.Operacion WHERE SeriOper = '0002' and NumOper = '001075903'
SELECT * from SGA.dbo.DetOper WHERE SeriOper = '0002' and NumOper = '001075903'

SELECT * from SGA.dbo.Deudas WHERE SeriDeud = '8888' and NumDeud = '01668228'

--SELECT * from SGA.dbo.NumeracionFE where SerieElec = 'B012' and NumeroElec = '00267233'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200267233'
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '888801668228'

select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobanteElectronico = 'B01200267233'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = ''

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0013000465588' and idComprobanteElectronico = 'B00100071769'
select top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0013000465588'

SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200267233'

-- Pago deuda pension
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobante = '0013000465588' and idComprobanteElectronico = 'B00100071769'
SELECT top 10 * from SGA.dbo.DetalleComprobante_Maestra where idComprobante = '0013000465588' and idComprobanteElectronico = 'B00100071769'

-- Pago matricula 2018
SELECT top 10 * from SGA.dbo.Comprobantes_Mestra where idComprobanteElectronico = 'B01200267233'

select top 10 * from SGA.dbo.Notas_Cred_Deb
select distinct Tip_Nota  from SGA.dbo.Notas_Cred_Deb 




