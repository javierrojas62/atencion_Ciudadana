import 'package:flutter/material.dart';

// Mapa para pasar del nombre del ícono que viene en el json al IconData real
final _icons = <String, IconData>{
  'water_damage': Icons.water_damage,
  'add_road': Icons.add_road,
  'lightbulb': Icons.lightbulb,
  'delete': Icons.delete,
};

// Devuelve el ícono a partir del nombre. Si no lo encuentra muestra uno genérico.
Icon getIcon(String nombreIcono) {
  return Icon(
    _icons[nombreIcono] ?? Icons.report_problem,
    color: const Color(0xFF00796B),
  );
}
