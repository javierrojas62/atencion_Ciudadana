-- =====================================================================
--  07 - Seguridad (RLS)
--  Qué puede ver y hacer cada rol. Regla general: no se elimina nada,
--  por eso nadie tiene permiso de DELETE.
--  Un usuario desactivado no tiene rol (mi_rol() = null): solo puede
--  leer su propio perfil, para que la app le avise que está desactivado.
-- =====================================================================

alter table public.provincias     enable row level security;
alter table public.departamentos  enable row level security;
alter table public.barrios        enable row level security;
alter table public.categorias     enable row level security;
alter table public.perfiles       enable row level security;
alter table public.altas_autorizadas enable row level security;
alter table public.reclamos       enable row level security;


-- ---------------------------------------------------------------------
-- Permisos base por tabla (las políticas deciden qué filas)
-- ---------------------------------------------------------------------
revoke all on public.provincias, public.departamentos, public.barrios,
              public.categorias, public.perfiles, public.altas_autorizadas,
              public.reclamos
  from anon, authenticated;

grant select on public.provincias, public.departamentos,
                public.categorias, public.barrios       to anon, authenticated;
grant insert, update on public.barrios                 to authenticated;
grant select, update on public.perfiles                to authenticated;
grant select, insert, update on public.reclamos        to authenticated;

grant select on public.barrios_con_pendientes, public.resumen_reclamos,
                public.resueltos_por_operario           to authenticated;

grant execute on function public.mi_rol() to authenticated;


-- ---------------------------------------------------------------------
-- Datos de referencia
-- ---------------------------------------------------------------------
create policy "todos ven provincias"
  on public.provincias for select to anon, authenticated using (true);

create policy "todos ven departamentos"
  on public.departamentos for select to anon, authenticated using (true);

create policy "todos ven categorias activas"
  on public.categorias for select to anon, authenticated using (activa);


-- ---------------------------------------------------------------------
-- Barrios
-- ---------------------------------------------------------------------
-- En el registro y en el reporte solo aparecen los activos.
-- Operario y admin ven todos (un reclamo viejo puede ser de un barrio desactivado).
create policy "ver barrios"
  on public.barrios for select to anon, authenticated
  using (activo or public.mi_rol() in ('operario', 'admin'));

create policy "admin crea barrios"
  on public.barrios for insert to authenticated
  with check (public.mi_rol() = 'admin');

create policy "admin edita barrios"
  on public.barrios for update to authenticated
  using (public.mi_rol() = 'admin')
  with check (public.mi_rol() = 'admin');


-- ---------------------------------------------------------------------
-- Perfiles
-- ---------------------------------------------------------------------
create policy "cada uno ve su perfil"
  on public.perfiles for select to authenticated
  using (id = auth.uid());

create policy "admin ve todos los perfiles"
  on public.perfiles for select to authenticated
  using (public.mi_rol() = 'admin');

-- El admin edita vecinos y operarios (nombre, barrio, parcela, activo).
-- No puede editar a otro admin ni a sí mismo.
create policy "admin edita vecinos y operarios"
  on public.perfiles for update to authenticated
  using (public.mi_rol() = 'admin' and rol <> 'admin')
  with check (public.mi_rol() = 'admin' and rol <> 'admin');

-- altas_autorizadas: sin políticas = nadie accede desde la app.


-- ---------------------------------------------------------------------
-- Reclamos
-- ---------------------------------------------------------------------
-- El vecino crea reclamos a su nombre, en un barrio activo.
-- No tiene política de lectura: no ve historial.
create policy "vecino crea reclamos"
  on public.reclamos for insert to authenticated
  with check (
    public.mi_rol() = 'vecino'
    and vecino_id = auth.uid()
    and exists (select 1 from public.barrios b where b.id = barrio_id and b.activo)
  );

-- El operario ve todos los reclamos y realiza los pendientes.
create policy "operario ve reclamos"
  on public.reclamos for select to authenticated
  using (public.mi_rol() = 'operario');

create policy "operario realiza reclamos pendientes"
  on public.reclamos for update to authenticated
  using (public.mi_rol() = 'operario' and estado = 'pendiente')
  with check (public.mi_rol() = 'operario');

-- El admin ve todos los reclamos (dashboard y hashes).
create policy "admin ve reclamos"
  on public.reclamos for select to authenticated
  using (public.mi_rol() = 'admin');
