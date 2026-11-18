-- =====================================================================
--  Datos iniciales
--  Ejecutar después de los 9 archivos de esquema/
-- =====================================================================

insert into public.provincias (nombre) values ('San Juan');

insert into public.departamentos (provincia_id, nombre)
select id, 'Rawson' from public.provincias where nombre = 'San Juan';

insert into public.barrios (departamento_id, nombre)
select d.id, b.nombre
from public.departamentos d,
     (values
       ('Villa Krause'),
       ('Barrio Capitán Lazo'),
       ('Barrio Güemes'),
       ('Barrio San Ricardo'),
       ('Barrio Residencial Rawson'),
       ('Villa Chacabuco'),
       ('Villa Bolaños'),
       ('Médano de Oro'),
       ('Colonia Rodas'),
       ('El Medanito')
     ) as b(nombre)
where d.nombre = 'Rawson';

insert into public.categorias (slug, nombre, descripcion, icono) values
  ('cuneta',    'Cuneta sucia',     'Cunetas tapadas o con agua estancada', 'water_damage'),
  ('bache',     'Bache',            'Pozos o calles rotas',                 'add_road'),
  ('luminaria', 'Luminaria rota',   'Luces de la calle apagadas o dañadas', 'lightbulb'),
  ('basura',    'Basura acumulada', 'Residuos en la vereda o baldíos',      'delete');
