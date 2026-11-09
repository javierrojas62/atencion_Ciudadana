// Categoría de reclamo (tabla categorias de Supabase)
class CategoriaModel {
  final int id;
  final String slug; // 'cuneta', 'bache', ...
  final String nombre; // 'Cuneta sucia'
  final String descripcion;
  final String icono; // nombre del ícono de Material

  CategoriaModel({
    required this.id,
    required this.slug,
    required this.nombre,
    required this.descripcion,
    required this.icono,
  });

  // Convierte la fila que devuelve Supabase en un objeto
  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'],
      slug: json['slug'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'],
    );
  }
}
