import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/pages/admin/barrios_tab.dart';
import 'package:atencion_ciudadana/src/pages/admin/dashboard_tab.dart';
import 'package:atencion_ciudadana/src/pages/admin/usuarios_tab.dart';
import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';

// Pantalla del administrador.
// Solo arma las 3 pestañas; cada una está en su propio archivo
// dentro de la carpeta pages/admin.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de administración'),
          actions: const [BotonCerrarSesion()],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.location_city), text: 'Barrios'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [DashboardTab(), UsuariosTab(), BarriosTab()],
        ),
      ),
    );
  }
}
