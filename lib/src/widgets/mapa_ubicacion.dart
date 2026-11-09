import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Mapa chico con un marcador en un punto.
// Lo usa el vecino (dónde está el problema) y lo va a usar el operario
// (adónde tiene que ir). Mapa libre de OpenStreetMap, como en clase.
class MapaUbicacion extends StatelessWidget {
  final LatLng punto;
  final double alto;

  const MapaUbicacion({super.key, required this.punto, this.alto = 220});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: alto,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: punto,
            initialZoom: 16.5,
            // Se puede mover y hacer zoom, pero no rotar
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.atencion_ciudadana',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: punto,
                  width: 40,
                  height: 40,
                  // La punta del pin queda justo sobre el punto
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            // OpenStreetMap pide que se lo mencione en el mapa
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
