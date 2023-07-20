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




