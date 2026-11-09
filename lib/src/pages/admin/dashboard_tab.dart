import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/dashboard_model.dart';
import 'package:atencion_ciudadana/src/providers/admin_provider.dart';
import 'package:atencion_ciudadana/src/widgets/ancho_maximo.dart';

// Datos de las 3 consultas del dashboard, juntos
class _DatosDashboard {
  final ResumenModel resumen;
  final List<OperarioResueltosModel> operarios;
  final List<ReclamoResueltoModel> resueltos;

  _DatosDashboard(this.resumen, this.operarios, this.resueltos);
}

// Pestaña Dashboard: totales, resueltos por operario y los últimos
// reclamos resueltos con sus hashes (prueba de trazabilidad).
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late Future<_DatosDashboard> _datos = _cargar();

  // Las 3 consultas se hacen al mismo tiempo con Future.wait
  Future<_DatosDashboard> _cargar() async {
    final resultados = await Future.wait([
      adminProvider.resumen(),
      adminProvider.resueltosPorOperario(),
      adminProvider.ultimosResueltos(),
    ]);

    return _DatosDashboard(
      resultados[0] as ResumenModel,
      resultados[1] as List<OperarioResueltosModel>,
      resultados[2] as List<ReclamoResueltoModel>,
    );
  }

  Future<void> _recargar() async {
    setState(() {
      _datos = _cargar();
    });
    await _datos;
  }

  @override
  Widget build(BuildContext context) {
    return AnchoMaximo(
      child: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<_DatosDashboard>(
          future: _datos,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _crearMensaje(
                'No se pudieron cargar los datos. Deslizá hacia abajo para reintentar.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final datos = snapshot.data!;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _crearTotales(datos.resumen),
                const SizedBox(height: 24),
                _crearTitulo('Reclamos resueltos por operario'),
                _crearTablaOperarios(datos.operarios),
                const SizedBox(height: 24),
                _crearTitulo('Últimos reclamos resueltos'),
                if (datos.resueltos.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Todavía no hay reclamos resueltos.'),
                    ),
                  ),
                ...datos.resueltos.map(_crearTarjetaResuelto),
              ],
            );
          },
        ),
      ),
    );
  }

  // Tres tarjetas con los totales
  Widget _crearTotales(ResumenModel resumen) {
    return Row(
      children: [
        _crearNumero('Total', resumen.total, Icons.list_alt, Colors.teal),
        const SizedBox(width: 8),
        _crearNumero(
          'Pendientes',
          resumen.pendientes,
          Icons.schedule,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        _crearNumero(
          'Resueltos',
          resumen.resueltos,
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _crearNumero(String texto, int valor, IconData icono, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icono, color: color),
              const SizedBox(height: 8),
              Text(
                '$valor',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(texto, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearTablaOperarios(List<OperarioResueltosModel> operarios) {
    if (operarios.isEmpty) {
      return const Card(
        child: ListTile(title: Text('Todavía no hay operarios.')),
      );
    }

    return Card(
      // Por si en el celular la tabla no entra a lo ancho
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Operario')),
            DataColumn(label: Text('Resueltos'), numeric: true),
          ],
          rows: operarios
              .map(
                (o) => DataRow(
                  cells: [
                    DataCell(Text(o.nombreCompleto)),
                    DataCell(Text('${o.resueltos}')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // Reclamo resuelto con su hash inicial y su hash de cierre
  Widget _crearTarjetaResuelto(ReclamoResueltoModel reclamo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reclamo #${reclamo.id} · ${reclamo.categoria} · ${reclamo.barrio}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Resuelto por ${reclamo.operario} el ${reclamo.fecha}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _crearHash('Hash inicial', reclamo.hashInicial),
            const SizedBox(height: 8),
            _crearHash('Hash de cierre', reclamo.hashCierre),
          ],
        ),
      ),
    );
  }

  // El hash se puede seleccionar y copiar
  Widget _crearHash(String titulo, String hash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        SelectableText(
          hash,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Widget _crearTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _crearMensaje(String texto) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(40),
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
