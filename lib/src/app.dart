import 'package:flutter/material.dart';

import 'routes/routes.dart';

// App es el widget raíz. Lo llamo desde main.dart.
// Acá defino el MaterialApp con el tema general y las rutas de las pantallas.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atención Ciudadana',
      debugShowCheckedModeBanner: false,

      // Tema de la app: uso un color base verde azulado y Material 3,
      // así todos los botones, tarjetas e inputs toman el mismo estilo
      // sin repetirlo en cada pantalla.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        useMaterial3: true,

        // AppBar verde con letras blancas en todas las pantallas
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00796B),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        // Todas las tarjetas con el mismo borde redondeado
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
      ),

      // La primera pantalla es la HomePage ('/').
      // Las rutas están separadas en src/routes/routes.dart para no llenar este archivo.
      initialRoute: '/',
      routes: getAplicationRoutes(),
    );
  }
}
