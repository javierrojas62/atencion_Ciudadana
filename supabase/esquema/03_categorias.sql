-- =====================================================================
--  03 - Categorías de reclamo (reemplaza a data/categorias.json)
-- =====================================================================

create table public.categorias (
  id           smallint generated always as identity primary key,
  slug         text not null unique,      -- 'cuneta', 'bache', ...
  nombre       text not null,             -- 'Cuneta sucia'
  descripcion  text,
  icono        text not null,             -- nombre del ícono de Material
  activa       boolean not null default true
);
