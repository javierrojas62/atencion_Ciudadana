-- =====================================================================
--  10 - Historial del vecino y categoría "Otro"
--  (recomendaciones del 13/11/2026)
--
--  - Categoría "Otro": el vecino puede reportar algo que no está en las
--    opciones, contando qué es en el campo tipo_otro (obligatorio).
--  - Historial: el vecino ve sus propios reclamos.
--  - CRUD completo del Reclamo: mientras está PENDIENTE, el vecino puede
--    modificar la descripción o eliminarlo. Una vez RESUELTO queda
--    sellado: no se modifica ni se elimina (es el registro de la gestión).
--
--  Se ejecuta UNA vez, después de los archivos 01 a 09.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) Categoría "Otro" y columna para contar qué problema es
-- ---------------------------------------------------------------------
insert into public.categorias (slug, nombre, descripcion, icono)
values ('otro', 'Otro problema', 'Algo que no está en las opciones', 'help')
on conflict (slug) do nothing;

alter table public.reclamos add column tipo_otro text;


-- ¿La categoría es "Otro"?
create function public.es_categoria_otro(p_categoria smallint)
returns boolean
language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.categorias where id = p_categoria and slug = 'otro') $$;


-- Hash inicial en un solo lugar: lo usan el alta y la modificación
create function public.calcular_hash_inicial(r public.reclamos)
returns text
language sql immutable
as $$
  select encode(sha256(convert_to(
    concat_ws('|', r.id, r.vecino_id, r.categoria_id, r.barrio_id,
              r.descripcion, r.tipo_otro, r.foto_url, r.latitud, r.longitud,
              r.creado_en),
    'UTF8')), 'hex')
$$;


-- ---------------------------------------------------------------------
-- 2) ALTA: se agrega la validación de "Otro" (el resto queda igual)
-- ---------------------------------------------------------------------
create or replace function public.preparar_reclamo_nuevo()
returns trigger
language plpgsql
as $$
begin
  -- "Otro" necesita que el vecino cuente qué es; las demás no lo usan
  new.tipo_otro := nullif(trim(new.tipo_otro), '');
  if public.es_categoria_otro(new.categoria_id) then
    if new.tipo_otro is null then
      raise exception 'Contá qué tipo de problema es';
    end if;
  else
    new.tipo_otro := null;
  end if;

  new.estado              := 'pendiente';
  new.operario_id         := null;
  new.foto_reparacion_url := null;
  new.observacion         := null;
  new.resuelto_en         := null;
  new.hash_cierre         := null;
  new.creado_en           := now();

  new.hash_inicial := public.calcular_hash_inicial(new);

  return new;
end;
$$;


-- ---------------------------------------------------------------------
-- 3) MODIFICACIÓN: el mismo trigger maneja dos casos
--    A) sigue pendiente -> el vecino edita la descripción
--    B) pasa a resuelto -> el operario lo realiza (igual que antes)
-- ---------------------------------------------------------------------
create or replace function public.realizar_reclamo()
returns trigger
language plpgsql
as $$
begin
  if old.estado = 'resuelto' then
    raise exception 'Este reclamo ya fue resuelto';
  end if;

  -- A) Edición del vecino mientras está pendiente
  if new.estado = 'pendiente' then
    if auth.uid() is not null and auth.uid() is distinct from old.vecino_id then
      raise exception 'Solo el vecino que creó el reclamo puede modificarlo';
    end if;

    -- Solo se puede cambiar la descripción (y el texto de "Otro")
    if (new.vecino_id, new.categoria_id, new.barrio_id,
        new.foto_url, new.latitud, new.longitud, new.creado_en)
       is distinct from
       (old.vecino_id, old.categoria_id, old.barrio_id,
        old.foto_url, old.latitud, old.longitud, old.creado_en) then
      raise exception 'Solo se puede modificar la descripción del reclamo';
    end if;

    new.tipo_otro := nullif(trim(new.tipo_otro), '');
    if public.es_categoria_otro(old.categoria_id) then
      if new.tipo_otro is null then
        raise exception 'Contá qué tipo de problema es';
      end if;
    else
      new.tipo_otro := null;
    end if;

    -- Sigue sin datos de cierre
    new.operario_id         := null;
    new.foto_reparacion_url := null;
    new.observacion         := null;
    new.resuelto_en         := null;
    new.hash_cierre         := null;

    -- Todavía no se cerró: el hash inicial se recalcula con los datos nuevos
    new.hash_inicial := public.calcular_hash_inicial(new);
    return new;
  end if;

  -- B) El operario lo realiza
  if (new.vecino_id, new.categoria_id, new.barrio_id, new.descripcion,
      new.tipo_otro, new.foto_url, new.latitud, new.longitud, new.creado_en,
      new.hash_inicial)
     is distinct from
     (old.vecino_id, old.categoria_id, old.barrio_id, old.descripcion,
      old.tipo_otro, old.foto_url, old.latitud, old.longitud, old.creado_en,
      old.hash_inicial) then
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


-- ---------------------------------------------------------------------
-- 4) ELIMINACIÓN: un reclamo resuelto nunca se borra (ni desde el panel)
-- ---------------------------------------------------------------------
create function public.proteger_reclamo_resuelto()
returns trigger
language plpgsql
as $$
begin
  if old.estado = 'resuelto' then
    raise exception 'Un reclamo resuelto no se puede eliminar';
  end if;
  return old;
end;
$$;

create trigger antes_de_eliminar_reclamo
  before delete on public.reclamos
  for each row execute function public.proteger_reclamo_resuelto();


-- ---------------------------------------------------------------------
-- 5) Permisos del vecino sobre SUS reclamos
-- ---------------------------------------------------------------------
grant delete on public.reclamos to authenticated;

create policy "vecino ve sus reclamos"
  on public.reclamos for select to authenticated
  using (public.mi_rol() = 'vecino' and vecino_id = auth.uid());

create policy "vecino edita sus reclamos pendientes"
  on public.reclamos for update to authenticated
  using (public.mi_rol() = 'vecino' and vecino_id = auth.uid() and estado = 'pendiente')
  with check (public.mi_rol() = 'vecino' and vecino_id = auth.uid() and estado = 'pendiente');

create policy "vecino elimina sus reclamos pendientes"
  on public.reclamos for delete to authenticated
  using (public.mi_rol() = 'vecino' and vecino_id = auth.uid() and estado = 'pendiente');


-- ---------------------------------------------------------------------
-- 6) Fotos: cada uno puede borrar las fotos de su propia carpeta
--    (al eliminar un reclamo, la app borra también su foto)
-- ---------------------------------------------------------------------
create policy "cada uno borra fotos de su carpeta"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'reclamos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
