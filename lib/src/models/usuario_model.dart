// Usuario tal como lo ve el admin (tabla perfiles, con el nombre del barrio)
class UsuarioModel {
  final String id;
  final String email;
  final String nombre;
  final String apellido;
  final String rol; // 'vecino' u 'operario' (el admin no se lista)
  final bool activo;
  final int? barrioId; // solo vecinos
  final String? barrioNombre; // solo vecinos
  final String? parcela; // solo vecinos

  UsuarioModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    required this.activo,
    this.barrioId,
    this.barrioNombre,
    this.parcela,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final barrio = json['barrios'] as Map<String, dynamic>?;

    return UsuarioModel(
      id: json['id'],
      email: json['email'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      rol: json['rol'],
      activo: json['activo'],
      barrioId: json['barrio_id'],
      barrioNombre: barrio?['nombre'],
      parcela: json['parcela'],
    );
  }

  String get nombreCompleto => '$nombre $apellido';
  bool get esVecino => rol == 'vecino';
  String get rolTexto => esVecino ? 'Vecino' : 'Operario';
}
