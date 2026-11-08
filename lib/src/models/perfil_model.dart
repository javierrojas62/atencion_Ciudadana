// Datos del usuario que inició sesión (tabla perfiles de Supabase)
class PerfilModel {
  final String id;
  final String email;
  final String nombre;
  final String apellido;
  final String rol; // 'vecino', 'operario' o 'admin'
  final bool activo;

  PerfilModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.activo,
  });

  // Convierte la fila que devuelve Supabase en un objeto
  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: json['id'],
      email: json['email'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      rol: json['rol'],
      activo: json['activo'],
    );
  }

  // Pantalla a la que va cada rol después del login
  String get rutaInicio {
    switch (rol) {
      case 'admin':
        return 'admin';
      case 'operario':
        return 'operario';
      default:
        return 'reclamos';
    }
  }
}