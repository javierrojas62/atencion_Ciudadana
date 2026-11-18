-- =====================================================================
--  08 - Alta de operarios (solo admin)
--
--  Cómo crea el admin un operario desde la app:
--    1) llama a  supabase.rpc('admin_autorizar_operario', {'p_email': ...})
--    2) inmediatamente crea la cuenta con signUp (email, contraseña,
--       nombre y apellido)
--  Al registrarse, el email está autorizado, así que el perfil se crea
--  como operario (módulo 04). Cualquier otro registro entra como vecino.
--
--  Crear vecinos, editar y desactivar usuarios y barrios no necesita
--  funciones especiales: lo resuelven las políticas del módulo 07.
-- =====================================================================

create function public.admin_autorizar_operario(p_email text)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_email text := lower(trim(p_email));
begin
  if public.mi_rol() is distinct from 'admin' then
    raise exception 'Solo un administrador puede crear operarios';
  end if;

  if v_email is null or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'El email no es válido';
  end if;

  if exists (select 1 from public.perfiles where lower(email) = v_email) then
    raise exception 'Ya existe un usuario con ese email';
  end if;

  insert into public.altas_autorizadas (email, rol, autorizado_por)
  values (v_email, 'operario', auth.uid())
  on conflict (email) do update
    set rol = 'operario', autorizado_por = excluded.autorizado_por,
        creado_en = now();
end;
$$;

revoke execute on function public.admin_autorizar_operario(text) from public, anon;
grant  execute on function public.admin_autorizar_operario(text) to authenticated;
