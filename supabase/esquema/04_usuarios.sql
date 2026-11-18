-- =====================================================================
--  04 - Usuarios
--  Supabase Auth guarda email y contraseña (tabla auth.users).
--  Acá guardamos el resto: nombre, rol, barrio, parcela y si está activo.
-- =====================================================================

create table public.perfiles (
  id         uuid primary key references auth.users(id),
  email      text not null,
  nombre     text not null check (length(trim(nombre)) > 0),
  apellido   text not null check (length(trim(apellido)) > 0),
  rol        public.rol_usuario not null,
  activo     boolean not null default true,     -- desactivado = no puede entrar
  barrio_id  integer references public.barrios(id),
  parcela    text,
  creado_en  timestamptz not null default now(),

  -- El vecino siempre tiene barrio y parcela; los demás roles no
  constraint datos_segun_rol check (
    (rol = 'vecino' and barrio_id is not null and parcela is not null)
    or (rol <> 'vecino' and barrio_id is null and parcela is null)
  )
);


-- Emails autorizados a registrarse con un rol distinto de vecino:
--   operario -> los autoriza el admin desde la app (módulo 08)
--   admin    -> se carga una sola vez desde el SQL Editor (crear_admin.sql)
-- Nadie puede leer ni escribir esta tabla directamente desde la app.
create table public.altas_autorizadas (
  email           text primary key,
  rol             public.rol_usuario not null check (rol <> 'vecino'),
  autorizado_por  uuid references public.perfiles(id),
  creado_en       timestamptz not null default now()
);


-- Rol del usuario que está usando la app.
-- Si está desactivado devuelve null y no pasa ninguna regla de seguridad.
create function public.mi_rol()
returns public.rol_usuario
language sql stable security definer set search_path = public
as $$ select rol from public.perfiles where id = auth.uid() and activo $$;


-- Al crearse una cuenta en Supabase Auth se crea su perfil:
--   - si el email está autorizado -> operario o admin, según la autorización
--   - si no -> vecino (y tiene que traer barrio y parcela)
-- La app manda nombre, apellido, barrio_id y parcela como metadata del signUp.
create function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  datos       jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_barrio    integer := nullif(datos ->> 'barrio_id', '')::integer;
  v_rol       public.rol_usuario;
begin
  select rol into v_rol from public.altas_autorizadas where email = lower(new.email);

  if v_rol is not null then
    insert into public.perfiles (id, email, nombre, apellido, rol)
    values (new.id, new.email,
            coalesce(nullif(trim(datos ->> 'nombre'), ''), split_part(new.email, '@', 1)),
            coalesce(nullif(trim(datos ->> 'apellido'), ''), '-'),
            v_rol);

    delete from public.altas_autorizadas where email = lower(new.email);
  else
    if nullif(trim(datos ->> 'nombre'), '') is null
       or nullif(trim(datos ->> 'apellido'), '') is null then
      raise exception 'Completá tu nombre y apellido';
    end if;

    if not exists (select 1 from public.barrios where id = v_barrio and activo) then
      raise exception 'Elegí un barrio válido';
    end if;

    if nullif(trim(datos ->> 'parcela'), '') is null then
      raise exception 'Completá el número de parcela';
    end if;

    insert into public.perfiles (id, email, nombre, apellido, rol, barrio_id, parcela)
    values (new.id, new.email, datos ->> 'nombre', datos ->> 'apellido', 'vecino',
            v_barrio, nullif(trim(datos ->> 'parcela'), ''));
  end if;

  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();


-- Desde la app nadie puede cambiar el rol ni el email de un perfil.
-- (Desde el panel de Supabase sí, para crear el primer admin.)
create function public.proteger_perfil()
returns trigger
language plpgsql
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if new.rol is distinct from old.rol then
      raise exception 'El rol de un usuario no se puede cambiar';
    end if;
    if new.email is distinct from old.email or new.id is distinct from old.id then
      raise exception 'El email de un usuario no se puede cambiar';
    end if;
  end if;
  return new;
end;
$$;

create trigger antes_de_editar_perfil
  before update on public.perfiles
  for each row execute function public.proteger_perfil();
