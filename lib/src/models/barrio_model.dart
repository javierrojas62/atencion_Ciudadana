// Barrio del departamento (tabla barrios de Supabase)
class BarrioModel {
  final int id;
  final String nombre;
  final bool activo; // desactivado = no aparece en el registro ni en los reclamos

  BarrioModel({required this.id, required this.nombre, this.activo = true});

  // Convierte la fila que devuelve Supabase en un objeto.
  // Si la consulta no trae "activo" (registro y reclamo solo piden
  // los activos), lo tomo como activo.
  factory BarrioModel.fromJson(Map<String, dynamic> json) {
    return BarrioModel(
      id: json['id'],
      nombre: json['nombre'],
      activo: json['activo'] ?? true,
    );
  }
}
