// Barrio del departamento (tabla barrios de Supabase)
class BarrioModel {
  final int id;
  final String nombre;

  BarrioModel({required this.id, required this.nombre});

  // Convierte la fila que devuelve Supabase en un objeto
  factory BarrioModel.fromJson(Map<String, dynamic> json) {
    return BarrioModel(id: json['id'], nombre: json['nombre']);
  }
}
