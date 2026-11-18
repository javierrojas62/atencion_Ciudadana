-- =====================================================================
--  Reiniciar la base (OPCIONAL)
--  Borra todo lo de Atención Ciudadana para volver a cargar el esquema
--  desde cero. Usalo solo si ya ejecutaste una versión anterior.
--  Ojo: también borra los usuarios de Supabase Auth.
-- =====================================================================

drop trigger if exists al_crear_usuario on auth.users;

drop policy if exists "vecinos y operarios suben fotos a su carpeta" on storage.objects;
drop policy if exists "todos ven las fotos de reclamos"              on storage.objects;
drop policy if exists "cada uno borra fotos de su carpeta"           on storage.objects;
-- políticas de versiones anteriores
drop policy if exists "subir fotos a mi carpeta" on storage.objects;
drop policy if exists "ver fotos de reclamos"    on storage.objects;

drop view  if exists public.barrios_con_pendientes, public.resumen_reclamos,
                     public.resueltos_por_operario cascade;
drop table if exists public.reclamos, public.altas_autorizadas, public.altas_operario,
                     public.perfiles, public.categorias, public.barrios,
                     public.departamentos, public.provincias cascade;

drop function if exists public.crear_perfil_nuevo_usuario, public.proteger_perfil,
                        public.preparar_reclamo_nuevo, public.realizar_reclamo,
                        public.controlar_cambio_reclamo, public.mi_rol,
                        public.mi_departamento, public.verificar_admin,
                        public.admin_autorizar_operario, public.admin_cambiar_rol,
                        public.admin_bloquear_usuario, public.admin_eliminar_usuario,
                        -- agregadas en 10_historial_y_otro.sql
                        public.es_categoria_otro, public.calcular_hash_inicial,
                        public.proteger_reclamo_resuelto cascade;

drop type if exists public.estado_reclamo, public.rol_usuario cascade;

delete from auth.users;
