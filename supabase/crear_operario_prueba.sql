-- =====================================================================
--  Crear un operario de prueba (mientras no esté el panel del admin)
--
--  1) Reemplazá el email y ejecutá este archivo en el SQL Editor.
--  2) En Supabase > Authentication > Users > Add user > Create new user,
--     creá la cuenta con ese mismo email y una contraseña
--     (tildá "Auto Confirm User").
--  3) Ejecutá el update de abajo para ponerle nombre y apellido.
--
--  Al crearse la cuenta, la base ve que el email está autorizado como
--  operario y le arma el perfil con ese rol.
-- =====================================================================

insert into public.altas_autorizadas (email, rol)
values (lower('operario@gmail.com'), 'operario');


-- Paso 3 (después de crear la cuenta en Authentication):
-- update public.perfiles
-- set nombre = 'Juan', apellido = 'Pérez'
-- where email = 'operario@gmail.com';
