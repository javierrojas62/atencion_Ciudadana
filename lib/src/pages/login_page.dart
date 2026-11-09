import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/providers/auth_provider.dart';

// Pantalla de inicio de sesión.
// Valida los campos, inicia sesión con Supabase y manda a cada usuario
// a la pantalla de su rol (vecino, operario o admin).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Key del formulario para poder validar todos los campos juntos
  final _formKey = GlobalKey<FormState>();

  // Controllers para leer lo que escribe el usuario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _ocultarPassword = true;
  bool _cargando = false;

  // Libero los controllers cuando se cierra la pantalla
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      // El AppBar ya trae la flecha para volver a la HomePage
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            const SizedBox(height: 24),

            // Mismo estilo de logo que la HomePage
            CircleAvatar(
              radius: 45,
              backgroundColor: colores.primaryContainer,
              child: Icon(Icons.lock_person, size: 50, color: colores.primary),
            ),
            const SizedBox(height: 16),

            Text(
              'Bienvenido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colores.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ingresá con tu email y contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _crearEmail(),
            const SizedBox(height: 16),
            _crearPassword(),
            const SizedBox(height: 32),
            _crearBoton(),
          ],
        ),
      ),
    );
  }

  // Campo email. Con keyboardType aparece el @ en el teclado
  Widget _crearEmail() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'tuemail@gmail.com',
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresá tu email';
        }
        if (!value.contains('@')) {
          return 'El email no es válido';
        }
        return null;
      },
    );
  }

  // Campo contraseña, con el ojito para mostrarla u ocultarla
  Widget _crearPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _ocultarPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _ocultarPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() => _ocultarPassword = !_ocultarPassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresá tu contraseña';
        }
        if (value.length < 6) {
          return 'Mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  // Mientras carga deshabilito el botón y muestro el circulito
  Widget _crearBoton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _cargando ? null : _iniciarSesion,
      child: _cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Ingresar'),
    );
  }

  Future<void> _iniciarSesion() async {
    // Si algún campo no pasa la validación no sigo
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final perfil = await authProvider.iniciarSesion(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      // Voy a la pantalla de su rol y borro el historial,
      // así con "atrás" no vuelve al login
      Navigator.pushNamedAndRemoveUntil(
        context,
        perfil.rutaInicio,
        (route) => false,
      );
    } on LoginException catch (e) {
      if (!mounted) return;
      _mostrarAlerta(e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Alerta con el motivo por el que no pudo entrar
  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('No se pudo ingresar'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
