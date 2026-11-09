import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/barrios_provider.dart';

// Pantalla de registro. Solo la usan los vecinos:
// a los operarios los crea el admin desde su panel.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parcelaController = TextEditingController();

  // Los barrios se piden una sola vez al abrir la pantalla.
  // Si lo pusiera directo en el FutureBuilder, se volverían a pedir
  // cada vez que se redibuja (por ejemplo al tocar el ojito).
  late final Future<List<BarrioModel>> _barrios =
      barriosProvider.cargarActivos();
  int? _barrioSeleccionado;

  bool _ocultarPassword = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parcelaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            const Text(
              'Completá tus datos para empezar a reportar los problemas de tu barrio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 24),

            _crearCampo(
              controller: _nombreController,
              label: 'Nombre',
              icono: Icons.person,
            ),
            const SizedBox(height: 16),
            _crearCampo(
              controller: _apellidoController,
              label: 'Apellido',
              icono: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _crearEmail(),
            const SizedBox(height: 16),
            _crearPassword(),
            const SizedBox(height: 16),
            _crearDropdownBarrios(),
            const SizedBox(height: 16),
            _crearCampo(
              controller: _parcelaController,
              label: 'Número de parcela',
              icono: Icons.home,
              hint: 'Ej: 12-345',
            ),
            const SizedBox(height: 32),

            _crearBoton(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tenés cuenta?'),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, 'login'),
                  child: const Text('Iniciá sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Campo de texto común (nombre, apellido, parcela).
  // Lo armo una vez y lo reutilizo cambiando solo lo que necesito.
  Widget _crearCampo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Completá este campo';
        }
        return null;
      },
    );
  }

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

  Widget _crearPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _ocultarPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        helperText: 'Mínimo 6 caracteres',
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
          return 'Ingresá una contraseña';
        }
        if (value.length < 6) {
          return 'Mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  // Los barrios vienen de Supabase, por eso uso un FutureBuilder
  Widget _crearDropdownBarrios() {
    return FutureBuilder<List<BarrioModel>>(
      future: _barrios,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'No se pudieron cargar los barrios. Revisá tu conexión.',
            style: TextStyle(color: Colors.red),
          );
        }

        final barrios = snapshot.data ?? [];
        final cargando = snapshot.connectionState == ConnectionState.waiting;

        return DropdownButtonFormField<int>(
          initialValue: _barrioSeleccionado,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: cargando ? 'Cargando barrios...' : 'Barrio',
            prefixIcon: const Icon(Icons.location_on),
          ),
          items: barrios
              .map(
                (barrio) => DropdownMenuItem(
                  value: barrio.id,
                  child: Text(barrio.nombre),
                ),
              )
              .toList(),
          onChanged: (valor) => setState(() => _barrioSeleccionado = valor),
          validator: (valor) => valor == null ? 'Elegí tu barrio' : null,
        );
      },
    );
  }

  Widget _crearBoton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _cargando ? null : _registrarse,
      child: _cargando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Crear cuenta'),
    );
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final perfil = await authProvider.registrarVecino(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        barrioId: _barrioSeleccionado!,
        parcela: _parcelaController.text.trim(),
      );

      if (!mounted) return;

      // Supabase pide confirmar el email antes de poder entrar
      if (perfil == null) {
        _mostrarAlerta(
          'Cuenta creada',
          'Te enviamos un email para confirmar tu cuenta. '
              'Cuando lo confirmes, iniciá sesión.',
          irAlLogin: true,
        );
        return;
      }

      // Quedó logueado: lo saludo y lo llevo a su pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido, ${perfil.nombre}!')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        perfil.rutaInicio,
        (route) => false,
      );
    } on LoginException catch (e) {
      if (!mounted) return;
      _mostrarAlerta('No se pudo crear la cuenta', e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarAlerta(String titulo, String mensaje, {bool irAlLogin = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (irAlLogin) {
                  Navigator.pushReplacementNamed(context, 'login');
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
