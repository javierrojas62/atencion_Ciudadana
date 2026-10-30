import 'package:flutter/material.dart';

// Pantalla de inicio de sesión.
// Por ahora el usuario está harcodeado acá. Cuando tenga la API en Laravel
// esto se reemplaza por el POST al login y se redirige según el rol.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Usuario de prueba (harcodeado hasta tener el backend)
  final String _emailValido = 'vecino@gmail.com';
  final String _passwordValido = '123456';

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
    return Scaffold(
      // El AppBar ya trae la flecha para volver a la HomePage
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.lock_person,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            _crearEmail(),
            const SizedBox(height: 16),
            _crearPassword(),
            const SizedBox(height: 32),
            _crearBoton(),
            const SizedBox(height: 24),

            // Ayuda para la presentación, después lo saco
            const Text(
              'Usuario de prueba: vecino@gmail.com / 123456',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
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

  // Mientras "carga" deshabilito el botón y muestro el circulito
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

    // Simulo la espera de la respuesta del servidor
    await Future.delayed(const Duration(seconds: 1));

    // Chequeo que la pantalla siga abierta antes de usar el context
    if (!mounted) return;
    setState(() => _cargando = false);

    // TODO: reemplazar por la llamada a la API de Laravel
    if (_emailController.text.trim() == _emailValido &&
        _passwordController.text == _passwordValido) {
      // Uso pushReplacementNamed para que con "atrás" no vuelva al login
      Navigator.pushReplacementNamed(context, 'reclamos');
    } else {
      _mostrarAlerta();
    }
  }

  // Alerta cuando el usuario o la contraseña no coinciden
  void _mostrarAlerta() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('No se pudo ingresar'),
          content: const Text('El email o la contraseña son incorrectos.'),
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
