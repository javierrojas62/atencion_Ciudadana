# 🏘️ Atención Ciudadana

Aplicación móvil desarrollada en **Flutter** para que los vecinos de cada departamento reporten problemas en la vía pública (cunetas sucias, baches, luminarias apagadas, basura acumulada) y un reparador asignado a la zona los resuelva, cerrando el reclamo con evidencia fotográfica del trabajo realizado.

> Trabajo integrador de la materia **Desarrollo Mobile** – Universidad Nacional de San Juan.

---

## 📌 Idea del proyecto

El vecino se registra, saca una foto del problema, la app toma su ubicación GPS y agrega una breve descripción. El reclamo se deriva al reparador responsable de ese departamento, quien realiza el trabajo y lo cierra subiendo una foto de la reparación, dejando un registro de **antes y después**.

Cada solicitud genera un **hash** único, y al finalizar la obra se genera un nuevo hash encadenado al primero. Esto permite llevar una trazabilidad verificable de los reclamos atendidos y publicar cuántas solicitudes se resolvieron durante una gestión.

---

## ✨ Funcionalidades

1. **Registro y roles**: login y autenticación con perfiles de vecino, reparador y administrador. El vecino se registra con su número de parcela como domicilio.
2. **Reporte de incidentes**: creación de reclamos con foto (cámara o galería), geolocalización GPS automática, categoría y descripción.
3. **Organización territorial**: estructura provincia → departamento → barrio, con cada reclamo asociado a su zona.
4. **Asignación por zona**: los reclamos se derivan a los reparadores del departamento correspondiente.
5. **Cierre con evidencia**: el reparador finaliza el reclamo con una foto del trabajo terminado (antes/después).
6. **Seguimiento de estado**: pendiente → en proceso → resuelto, visible para el vecino.
7. **Mapa de reclamos**: visualización de los reportes del departamento con marcadores según su estado.
8. **Notificaciones**: aviso al vecino cuando su reclamo es tomado y cuando es resuelto.
9. **Historial**: reclamos propios (vecino) y trabajos realizados (reparador).
10. **Trazabilidad con hash**: hash inicial por solicitud y hash de cierre encadenado para verificar los reclamos atendidos.

---

## 🛠️ Tecnologías

| Capa | Tecnología |
|------|------------|
| App móvil | Flutter / Dart |
| Backend (API REST) | Laravel (PHP) |
| Base de datos | MySQL |
| Mapas y ubicación | `geolocator`, `google_maps_flutter` / `flutter_map` |
| Cámara | `image_picker` |
| Permisos | `permission_handler` |

---

## 📱 Permisos de Android utilizados

- **Cámara**: para fotografiar el incidente y la reparación.
- **Ubicación**: para registrar las coordenadas exactas del reclamo.
- **Almacenamiento / galería**: para adjuntar imágenes existentes.
- **Notificaciones**: para avisar cambios de estado.

---

## 🚀 Instalación

### Requisitos
- Flutter SDK (canal stable)
- Android Studio o un dispositivo Android con depuración USB
- PHP 8.x, Composer y MySQL (para el backend)

### App móvil
```bash
git clone https://github.com/javierrojas62/atencion-ciudadana.git
cd atencion-ciudadana
flutter pub get
flutter run
```

### Backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Configurar la URL de la API en la app (por ejemplo en `lib/config/api.dart`).

---

## 📂 Estructura del proyecto

```
atencion-ciudadana/
├── lib/
│   ├── config/        # Configuración (URL de la API, constantes)
│   ├── models/        # Modelos de datos (Usuario, Reclamo, Departamento)
│   ├── services/      # Conexión con la API, ubicación, cámara
│   ├── screens/       # Pantallas (login, mapa, nuevo reclamo, detalle)
│   └── widgets/       # Componentes reutilizables
├── backend/           # API en Laravel
└── README.md
```

---

## 🔍 Aplicaciones similares

- **BA 147**: limitada a la Ciudad de Buenos Aires y no muestra evidencia de la reparación realizada.
- **SeeClickFix / FixMyStreet**: pensadas para otros países, no se adaptan a la organización por departamentos de Argentina ni tienen un rol de reparador que cierre el reclamo con foto.

**Diferencial**: organización por departamento y barrio, asignación por zona, cierre con evidencia fotográfica y trazabilidad de reclamos mediante hash encadenado.

---

## 🗺️ Estado del proyecto

🚧 En desarrollo (MVP)

- [ ] Login y registro con roles
- [ ] Creación de reclamos con foto y GPS
- [ ] Mapa de reclamos
- [ ] Panel del reparador y cierre con foto
- [ ] Hash de solicitud y de cierre
- [ ] Notificaciones

---

## 👤 Autor

**Javier Andrés Rojas Masuelli**
GitHub: [@javierrojas62](https://github.com/javierrojas62)
