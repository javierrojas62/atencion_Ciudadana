-- =====================================================================
--  02 - Territorio: provincia -> departamento -> barrio
--  Para la demo hay una provincia (San Juan), un departamento (Rawson)
--  y sus barrios. El admin gestiona los barrios.
-- =====================================================================

create table public.provincias (
  id      smallint generated always as identity primary key,
  nombre  text not null unique
);

create table public.departamentos (
  id            smallint generated always as identity primary key,
  provincia_id  smallint not null references public.provincias(id),
  nombre        text not null,
  unique (provincia_id, nombre)
);

create table public.barrios (
  id               integer generated always as identity primary key,
  departamento_id  smallint not null references public.departamentos(id),
  nombre           text not null check (length(trim(nombre)) > 0),
  activo           boolean not null default true,  -- desactivado = no aparece para elegir
  unique (departamento_id, nombre)
);
