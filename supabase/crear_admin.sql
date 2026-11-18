-- =====================================================================
--  Crear el primer administrador (se hace una sola vez)
--
--  1) Reemplazá el email y ejecutá este archivo en el SQL Editor.
--  2) En Supabase > Authentication > Users > Add user > Create new user,
--     creá la cuenta con ese mismo email y una contraseña
--     (marcá "Auto Confirm User").
--  Al crearse la cuenta, la base ve que el email está autorizado como
--  admin y le arma el perfil con ese rol.
-- =====================================================================

insert into public.altas_autorizadas (email, rol)
values (lower('tu_email@gmail.com'), 'admin');
