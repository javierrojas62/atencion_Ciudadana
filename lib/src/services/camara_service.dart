import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Los 3 estados posibles de un permiso (como vimos en clase)
enum ResultadoPermiso { otorgado, denegado, denegadoPermanente }

// Servicio de cámara: pide el permiso y saca la foto.
// Lo separo de las pantallas porque lo usan el vecino (foto del problema)
// y el operario (foto de la reparación).
class CamaraService {
  final ImagePicker _imagePicker = ImagePicker();

  // Pide el permiso de cámara con permission_handler
  Future<ResultadoPermiso> pedirPermisoCamara() async {
    // En el navegador no hay permisos de Android: Chrome pregunta solo
    if (kIsWeb) return ResultadoPermiso.otorgado;

    var status = await Permission.camera.status;

    if (status.isDenied) {
      // Solicitamos acceso
      status = await Permission.camera.request();
    }

    if (status.isGranted) return ResultadoPermiso.otorgado;
    if (status.isPermanentlyDenied) return ResultadoPermiso.denegadoPermanente;
    return ResultadoPermiso.denegado;
  }

  // Abre la cámara y devuelve la foto, o null si el usuario canceló.
  // La achico un poco para que no pese tanto al subirla.
  Future<XFile?> tomarFoto() async {
    return _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
  }

  // Si el permiso quedó bloqueado, la única forma es desde los ajustes del celular
  Future<void> abrirAjustes() async {
    await openAppSettings();
  }
}

// Instancia que uso desde las pantallas
final camaraService = CamaraService();
