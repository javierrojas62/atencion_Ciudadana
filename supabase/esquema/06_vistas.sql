-- =====================================================================
--  06 - Vistas
--  Consultas ya armadas que la app lee como si fueran tablas.
--  security_invoker = true: respetan los permisos de quien consulta.
-- =====================================================================

-- Operario: barrios que tienen reclamos pendientes, con la cantidad
create view public.barrios_con_pendientes
with (security_invoker = true) as
select b.id, b.nombre, count(*) as pendientes
from public.reclamos r
join public.barrios b on b.id = r.barrio_id
where r.estado = 'pendiente'
group by b.id, b.nombre
order by b.nombre;


-- Admin: totales del dashboard
create view public.resumen_reclamos
with (security_invoker = true) as
select
  count(*)                                       as total,
  count(*) filter (where estado = 'pendiente')   as pendientes,
  count(*) filter (where estado = 'resuelto')    as resueltos
from public.reclamos;


-- Admin: cantidad de reclamos resueltos por cada operario
create view public.resueltos_por_operario
with (security_invoker = true) as
select p.id, p.nombre, p.apellido, count(r.id) as resueltos
from public.perfiles p
left join public.reclamos r on r.operario_id = p.id and r.estado = 'resuelto'
where p.rol = 'operario'
group by p.id, p.nombre, p.apellido
order by resueltos desc, p.apellido;
