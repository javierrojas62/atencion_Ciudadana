-- =====================================================================
--  01 - Tipos
-- =====================================================================

-- Cada usuario tiene un solo rol, y no cambia nunca:
--   vecino   -> se registra solo desde la app y envía reportes
--   operario -> lo crea el admin; resuelve los reportes
--   admin    -> se crea una vez desde el panel de Supabase
create type public.rol_usuario as enum ('vecino', 'operario', 'admin');

-- Un reclamo nace pendiente y pasa a resuelto. No hay vuelta atrás.
create type public.estado_reclamo as enum ('pendiente', 'resuelto');
