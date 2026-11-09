import 'package:flutter/material.dart';

// Página principal (bienvenida).
// Es lo primero que ve el usuario al abrir la app: explica de qué se trata
// y le da las opciones de iniciar sesión o registrarse.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Categorías de reclamos que se van a poder reportar.
  // Las muestro acá como chips para que el vecino vea qué tipo de problemas puede cargar.
  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Cunetas', 'icono': Icons.water_damage},
    {'nombre': 'Baches', 'icono': Icons.add_road},
    {'nombre': 'Luminarias', 'icono': Icons.lightbulb},
    {'nombre': 'Basura', 'icono': Icons.delete},
  ];

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      // SafeArea para que no se meta el contenido debajo de la barra de estado
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo provisorio con un ícono hasta tener uno propio
              CircleAvatar(
                radius: 50,
                backgroundColor: colores.primaryContainer,
                child: Icon(
                  Icons.location_city,
                  size: 56,
                  color: colores.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Atención Ciudadana',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colores.primary,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Reportá problemas en la vía pública de tu barrio. '
                'Sacá una foto, mandá tu ubicación y seguí el estado '
                'de tu reclamo hasta que se resuelva.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Chips con las categorías. Uso Wrap para que si no entran en
              // una fila pasen solas a la siguiente.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _categorias
                    .map(
                      (cat) => Chip(
                        avatar: Icon(cat['icono'], size: 18),
                        label: Text(cat['nombre']),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 48),

              // Botón principal: va a la pantalla de login (ruta definida en routes.dart)
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pushNamed(context, 'login'),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 12),

              // Registro: solo para vecinos (a los operarios los crea el admin)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pushNamed(context, 'registro'),
                child: const Text('Registrarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
