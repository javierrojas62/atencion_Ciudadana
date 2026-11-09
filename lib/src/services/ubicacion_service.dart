import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Error con un mensaje listo para mostrar.
// permanente = el usuario bloqueó el permiso y hay que ir a los ajustes.
class UbicacionException implements Exception {
  final String mensaje;
  final bool permanente;

  UbicacionException(this.mensaje, {this.permanente = false});
}

// Servicio de ubicación: chequea el GPS, pide el permiso y toma la posición.
// Sigue los mismos pasos que vimos en la clase de mapas.
class UbicacionService {
  Future<LatLng> obtenerUbicacionActual() async {
    // 1) ¿Está prendido el GPS?
    final gpsActivo = await Geolocator.isLocationServiceEnabled();
    if (!gpsActivo) {
      throw UbicacionException('Activá la ubicación (GPS) del celular.');
    }

    // 2) ¿Tenemos permiso? Si no, lo pedimos
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw UbicacionException(
          'Necesitamos tu ubicación para marcar dónde está el problema.',
        );
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw UbicacionException(
        'El permiso de ubicación está bloqueado. Habilitalo desde los ajustes.',
        permanente: true,
      );
    }

    // 3) Tomamos la posición actual
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(posicion.latitude, posicion.longitude);
    } catch (_) {
      throw UbicacionException(
        'No se pudo obtener tu ubicación. Probá de nuevo al aire libre.',
      );
    }
  }

  Future<void> abrirAjustes() async {
    await Geolocator.openAppSettings();
  }
}

// Instancia que uso desde las pantallas
final ubicacionService = UbicacionService();
