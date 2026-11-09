// Modelos del dashboard del admin

// Totales de reclamos (vista resumen_reclamos)
class ResumenModel {
  final int total;
  final int pendientes;
  final int resueltos;

  ResumenModel({
    required this.total,
    required this.pendientes,
    required this.resueltos,
  });

  factory ResumenModel.fromJson(Map<String, dynamic> json) {
    return ResumenModel(
      total: json['total'],
      pendientes: json['pendientes'],
      resueltos: json['resueltos'],
    );
  }
}

// Cuántos reclamos resolvió cada operario (vista resueltos_por_operario)
class OperarioResueltosModel {
  final String nombre;
  final String apellido;
  final int resueltos;

  OperarioResueltosModel({
    required this.nombre,
    required this.apellido,
    required this.resueltos,
  });

  factory OperarioResueltosModel.fromJson(Map<String, dynamic> json) {
    return OperarioResueltosModel(
      nombre: json['nombre'],
      apellido: json['apellido'],
      resueltos: json['resueltos'],
    );
  }

  String get nombreCompleto => '$nombre $apellido';
}

// Reclamo resuelto con sus dos hashes (prueba de trazabilidad)
class ReclamoResueltoModel {
  final int id;
  final String categoria;
  final String barrio;
  final String operario;
  final DateTime resueltoEn;
  final String hashInicial;
  final String hashCierre;

  ReclamoResueltoModel({
    required this.id,
    required this.categoria,
    required this.barrio,
    required this.operario,
    required this.resueltoEn,
    required this.hashInicial,
    required this.hashCierre,
  });

  factory ReclamoResueltoModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categorias'] as Map<String, dynamic>?;
    final barrio = json['barrios'] as Map<String, dynamic>?;
    final operario = json['operario'] as Map<String, dynamic>?;

    return ReclamoResueltoModel(
      id: json['id'],
      categoria: categoria?['nombre'] ?? 'Sin categoría',
      barrio: barrio?['nombre'] ?? '',
      operario: operario == null
          ? '-'
          : '${operario['nombre']} ${operario['apellido']}',
      resueltoEn: DateTime.parse(json['resuelto_en']).toLocal(),
      hashInicial: json['hash_inicial'] ?? '',
      hashCierre: json['hash_cierre'] ?? '',
    );
  }

  // Fecha en formato dd/mm/aaaa hh:mm
  String get fecha {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(resueltoEn.day)}/${dos(resueltoEn.month)}/${resueltoEn.year} '
        '${dos(resueltoEn.hour)}:${dos(resueltoEn.minute)}';
  }
}
