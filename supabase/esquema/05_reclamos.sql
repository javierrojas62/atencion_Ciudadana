-- =====================================================================
--  05 - Reclamos
--  El vecino lo crea (pendiente) y el operario lo realiza (resuelto).
--  Cada paso genera un hash SHA-256 para la trazabilidad:
--    hash_inicial -> se calcula con los datos del reporte
--    hash_cierre  -> se calcula con el hash_inicial + los datos del cierre
-- =====================================================================

create table public.reclamos (
  id                   bigint generated always as identity primary key,

  -- Datos del reporte (los carga el vecino)
  vecino_id            uuid not null references public.perfiles(id),
  categoria_id         smallint not null references public.categorias(id),
  barrio_id            integer not null references public.barrios(id),
  descripcion          text not null check (length(trim(descripcion)) >= 5),
  foto_url             text not null,
  latitud              double precision not null check (latitud between -90 and 90),
  longitud             double precision not null check (longitud between -180 and 180),
  creado_en            timestamptz not null default now(),
  hash_inicial         text not null default '',

  -- Datos del cierre (los carga el operario)
  estado               public.estado_reclamo not null default 'pendiente',
  operario_id          uuid references public.perfiles(id),
  foto_reparacion_url  text,
  observacion          text,          -- opcional
  resuelto_en          timestamptz,
  hash_cierre          text,

  -- Un reclamo resuelto siempre tiene operario y foto del arreglo
  constraint cierre_completo check (
    estado = 'pendiente'
    or (operario_id is not null and foto_reparacion_url is not null and resuelto_en is not null)
  )
);

create index reclamos_pendientes_por_barrio on public.reclamos (estado, barrio_id);


-- Al crear un reclamo: siempre arranca pendiente, sin datos de cierre,
-- y se calcula el hash inicial.
create function public.preparar_reclamo_nuevo()
returns trigger
language plpgsql
as $$
begin
  new.estado              := 'pendiente';
  new.operario_id         := null;
  new.foto_reparacion_url := null;
  new.observacion         := null;
  new.resuelto_en         := null;
  new.hash_cierre         := null;
  new.creado_en           := now();

  new.hash_inicial := encode(sha256(convert_to(
    concat_ws('|', new.id, new.vecino_id, new.categoria_id, new.barrio_id,
              new.descripcion, new.foto_url, new.latitud, new.longitud,
              new.creado_en),
    'UTF8')), 'hex');

  return new;
end;
$$;

create trigger antes_de_crear_reclamo
  before insert on public.reclamos
  for each row execute function public.preparar_reclamo_nuevo();


-- Al realizar un reclamo: solo se puede pasar de pendiente a resuelto,
-- no se pueden tocar los datos del reporte, y se calcula el hash de cierre.
create function public.realizar_reclamo()
returns trigger
language plpgsql
as $$
begin
  if old.estado = 'resuelto' then
    raise exception 'Este reclamo ya fue resuelto';
  end if;

  if new.estado <> 'resuelto' then
    raise exception 'Un reclamo solo se puede marcar como resuelto';
  end if;

  if (new.vecino_id, new.categoria_id, new.barrio_id, new.descripcion,
      new.foto_url, new.latitud, new.longitud, new.creado_en, new.hash_inicial)
     is distinct from
     (old.vecino_id, old.categoria_id, old.barrio_id, old.descripcion,
      old.foto_url, old.latitud, old.longitud, old.creado_en, old.hash_inicial) then
    raise exception 'Los datos del reporte no se pueden modificar';
  end if;

  if nullif(trim(new.foto_reparacion_url), '') is null then
    raise exception 'Falta la foto de la reparación';
  end if;

  new.operario_id := coalesce(auth.uid(), new.operario_id);
  new.observacion := nullif(trim(new.observacion), '');
  new.resuelto_en := now();

  new.hash_cierre := encode(sha256(convert_to(
    concat_ws('|', new.hash_inicial, new.operario_id, new.foto_reparacion_url,
              new.observacion, new.resuelto_en),
    'UTF8')), 'hex');

  return new;
end;
$$;

create trigger antes_de_realizar_reclamo
  before update on public.reclamos
  for each row execute function public.realizar_reclamo();
