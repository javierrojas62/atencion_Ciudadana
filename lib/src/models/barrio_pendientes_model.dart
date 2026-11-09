// Barrio con la cantidad de reclamos pendientes
// (vista barrios_con_pendientes de Supabase). La usa el operario.
class BarrioPendientesModel {
  final int id;
  final String nombre;
  final int pendientes;

  BarrioPendientesModel({
    required this.id,
    required this.nombre,
    required this.pendientes,
  });

  factory BarrioPendientesModel.fromJson(Map<String, dynamic> json) {
    return BarrioPendientesModel(
      id: json['id'],
      nombre: json['nombre'],
      pendientes: json['pendientes'],
    );
  }
}
