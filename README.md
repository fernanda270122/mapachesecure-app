# Raccu — Control Parental Inteligente

Aplicación móvil de control parental desarrollada en Flutter. Permite a padres supervisar y gestionar el uso del dispositivo de sus hijos mediante bloqueo de apps, desafíos, recompensas y seguimiento de actividad.

## Características principales

**Para el padre**
- Panel de supervisión con actividad del hijo en tiempo real
- Creación y asignación de desafíos con evidencias revisables
- Tienda de recompensas y gestión de canjes pendientes
- Bloqueo remoto de aplicaciones en el dispositivo del hijo
- Configuración de perfil del hijo con avatar personalizable
- Consejos y guías para padres

**Para el hijo**
- Pantalla de inicio con resumen de desafíos y puntos
- Selección de avatar y temas visuales personalizados
- Vista de desafíos activos con subida de evidencias
- Tienda de recompensas canjeables con puntos ganados
- Pantalla de bloqueo cuando una app está restringida
- Evolución visual de la mascota (Mapache)

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter 3.44.4 / Dart ^3.11.5 | Framework principal |
| Firebase (Core + Messaging) | Autenticación y notificaciones push |
| Provider | Gestión de estado |
| flutter_background_service | Servicio de guardian en segundo plano |
| usage_stats | Estadísticas de uso de apps del hijo |
| system_alert_window | Pantalla de bloqueo sobre otras apps |
| flutter_local_notifications | Notificaciones locales |
| flutter_screenutil | Diseño responsivo |
| table_calendar | Calendario de actividad |
| shared_preferences | Persistencia local |

## Requisitos

- Flutter `>=3.44.4` (canal stable)
- Dart `^3.11.5`
- Android SDK (la app tiene soporte principal para Android)
- Cuenta de Firebase con proyecto configurado

## Instalación

```bash
# Clonar el repositorio
git clone <url-del-repo>
cd mapachesecure-app

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run
```

> La app requiere el archivo `lib/firebase_options.dart` generado con `flutterfire configure`. No se incluye en el repositorio por seguridad.

## Permisos requeridos (Android)

La app solicita los siguientes permisos en tiempo de ejecución:

- `PACKAGE_USAGE_STATS` — para leer el uso de apps del hijo
- `SYSTEM_ALERT_WINDOW` — para mostrar la pantalla de bloqueo sobre otras apps
- `POST_NOTIFICATIONS` — para notificaciones locales y push

## Arquitectura

```
lib/
├── main.dart                  # Entrada, rutas y splash
├── models/                    # Entidades de dominio (Usuario, Desafio, Recompensa…)
├── providers/                 # Estado global con Provider
├── screens/
│   ├── auth/                  # Login, registro, recuperación de contraseña
│   ├── onboarding/            # Flujo de bienvenida por rol
│   ├── padre/                 # Pantallas del rol padre
│   └── hijo/                  # Pantallas del rol hijo
├── services/                  # Comunicación con API, Firebase y guardian
├── theme/                     # Colores, paletas y fondos
└── utils/                     # Utilidades de responsividad
```

## Deep Links

La app responde al esquema `mapachesecure://` para el flujo de restablecimiento de contraseña:

```
mapachesecure://reset-password#access_token=<token>&type=recovery
```

## CI

El pipeline de GitHub Actions corre en cada push/PR a `main` y `dev`:

1. Verificación de formato (`dart format`)
2. Análisis estático (`flutter analyze`)
3. Tests con cobertura (`flutter test --coverage`)
4. Subida del reporte `lcov.info` como artefacto (7 días de retención)

## Roles de usuario

| Rol | Descripción |
|---|---|
| `padre` | Supervisa, configura restricciones y revisa evidencias |
| `hijo` | Completa desafíos, canjea recompensas, ve su actividad |

Al iniciar sesión, la app detecta el rol y redirige al flujo correspondiente. El onboarding se muestra una sola vez por usuario y rol.
