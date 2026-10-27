# ParkWise (Flutter · Android)

App de parqueaderos del campus (Universidad de los Andes). Este repo es la
versión Android en Flutter; la app iOS (SwiftUI) usa el mismo backend
(`Moviles-Backend`), así que una reserva hecha en una se ve en la otra.

El contrato de la API está en `../Moviles-Backend/docs/API.md`.

La BQ8 de Andrés está conectada al mismo flujo de datos de producción: Flutter
envía `forecast_viewed` y `availability_viewed` por `TelemetryClient`; la cola
Hive conserva los eventos sin conexión con su hora UTC original; el backend los
relaciona por usuario/día de Bogotá con check-ins reales de `reservations`; y
la tarjeta BQ8 del dashboard consulta el resumen SQL desde PostgreSQL. No hay
datos semilla en la app ni archivos exportados para completar esa tarjeta.

## Correr la app

Requisitos: Flutter 3.47+ (`flutter doctor` sin errores en "Android toolchain").

```bash
flutter pub get

# contra el backend desplegado en Render (es el valor por defecto)
flutter run

# contra el backend local desde el emulador
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# APK para instalar en cualquier celular
flutter build apk --release
```

`API_BASE_URL` se lee en `lib/core/config/api_config.dart`. Sin ese valor la
app usa `https://parkwise-api-a1f0.onrender.com`. El tráfico `http://` solo
está permitido en builds de debug.

Render se duerme después de 15 minutos sin uso y tarda cerca de un minuto en
despertar. Si la app dice que el servidor no responde, abre
`https://parkwise-api-a1f0.onrender.com/health` y espera a que conteste.

Para probar en un celular contra el backend local, conéctalo por cable y usa
`adb reverse tcp:3000 tcp:3000` con
`--dart-define=API_BASE_URL=http://localhost:3000`.

### En un celular Android (recomendado)

1. En el celular: **Ajustes → Acerca del teléfono → Información de software**
   y toca **Número de compilación** 7 veces.
2. **Ajustes → Opciones de desarrollador → Depuración USB** (activar).
   - Samsung: si el interruptor está gris, desactiva primero
     **Ajustes → Seguridad y privacidad → Bloqueador automático**.
3. Conecta el cable, acepta el popup "¿Permitir depuración USB?".
4. `flutter devices` debe mostrar tu celular. Luego `flutter run`.
5. La primera compilación tarda 2-3 min; las siguientes son rápidas.

### En emulador

Android Studio → Device Manager → crear un Pixel → Play. Luego `flutter run`.
Desde el emulador, `http://10.0.2.2:3000` es el `localhost` del computador,
por si quieres usar el backend local.

### Mientras corre

| Tecla | Acción |
|---|---|
| `r` | Hot reload: ves tu cambio en el celular al instante |
| `R` | Reinicio completo |
| `q` | Cerrar |

## Pruebas

```bash
flutter analyze   # sin warnings
flutter test      # unitarias + smoke test de pantallas
```

Las pruebas no llaman al backend: usan los mocks de
`lib/infrastructure/mock/` y, para el repositorio HTTP, un `MockClient` de
`package:http/testing.dart` con una caja de Hive temporal.

| Archivo | Qué prueba |
|---|---|
| `test/circuit_breaker_test.dart` | Estados cerrado, abierto y semiabierto; los 4xx no cuentan |
| `test/http_parking_repository_test.dart` | Devuelve la copia de Hive (`fromCache`) cuando falla la red |
| `test/reservation_history_offline_test.dart` | Historial SQLite por cuenta con fallback solo ante fallo de red |
| `test/local_persistence_test.dart` | Persistencia relacional SQLite y archivo JSON del carro |
| `test/local_cache_lru_test.dart` | LRU de 32 respuestas decodificadas y recuperación desde Hive tras eviction |
| `test/api_client_test.dart` | JSON grande procesado en isolate y respuesta inválida reportada |
| `test/reserve_view_model_test.dart` | Reserva 201, los dos 409, cuenta regresiva con `expiresAt`, check-in, aviso de vencimiento |
| `test/auth_view_model_test.dart` | Login, errores, registro y restauración de la sesión |
| `test/recommend_spot_test.dart` | El puesto recomendado es el libre con menos minutos; zona BQ4 |
| `test/no_spots_view_model_test.dart` | Parqueaderos cercanos, Navigate y el aviso de Notify me |
| `test/screens_smoke_test.dart` | Cada pantalla a 390 px y 320 px de ancho sin overflow |

## Arquitectura

Hexagonal (puertos y adaptadores) con MVVM en la presentación:

```
lib/
├── main.dart                    abre Hive, carga la sesión y arranca
├── app/
│   ├── dependencies.dart        arma adaptadores y view models (MultiProvider)
│   ├── parkwise_app.dart        MaterialApp + tema
│   └── app_router.dart          rutas de las pantallas que se abren encima
├── core/
│   ├── config/                  API_BASE_URL
│   ├── design/                  palette, typography, spacing, app_theme
│   ├── widgets/                 componentes reutilizables
│   └── format.dart              fechas, horas y cuenta regresiva
├── domain/                      Dart puro, sin Flutter ni paquetes
│   ├── entities/                ParkingLevel, ParkingSpot, Reservation, ...
│   ├── ports/                   ParkingRepository, ReservationRepository, ...
│   ├── services/                recommendSpot
│   └── errors.dart              ApiException, NetworkException, CircuitOpenException
├── infrastructure/              implementaciones de los puertos
│   ├── http/                    ApiClient, CircuitBreaker, repositorios, TelemetryClient
│   ├── device/                  geolocator, connectivity_plus, device_info_plus, url_launcher
│   ├── storage/                 SessionStore (secure storage), Hive
│   └── mock/                    versiones de mentira para las pruebas
└── presentation/
    ├── shell/                   AuthGate (login o app) y MainShell (tabs)
    ├── shared/                  manejo de red y mensajes de error
    └── screens/<pantalla>/      <pantalla>_screen.dart + <pantalla>_view_model.dart
```

Regla de dependencias: `presentation → domain ← infrastructure`. Las
pantallas solo escuchan su `ChangeNotifier` con `provider`; no hacen HTTP, ni
tocan Hive ni el GPS. Solo `app/dependencies.dart` conoce las
implementaciones concretas.

### Almacenamiento local

| Dónde | Qué |
|---|---|
| `flutter_secure_storage` | Token y usuario (el token nunca va a Hive ni a logs) |
| Hive `cache` | Última respuesta de niveles, puestos por nivel, edificios y reserva abierta |
| Hive `prefs` | Edificio destino elegido |
| Hive `telemetry` | Cola de eventos pendientes (máx. 200) |
| SQLite (`parkwise_local.db`) | Historial de reservas por usuario; respaldo transaccional para abrir Profile offline |
| `parked_vehicle.json` en Application Support | Última ubicación del carro, escrita al guardar/check-in y disponible offline |

El historial SQLite está particionado por `user_id`, tiene clave primaria
compuesta y un índice por usuario/fecha. Solo se usa como respaldo si falla la
red; un usuario nunca recibe el historial cacheado de otra cuenta. Se borra al
cerrar sesión. La ubicación del carro se guarda como JSON en el directorio
privado de la app, no como archivo descargado ni como fuente de analítica.

`LocalCache` mantiene además un LRU de hasta 32 respuestas decodificadas en
memoria; Hive sigue siendo la copia persistente para uso offline. El límite
evita crecimiento sin cota y la política descarta primero lo menos usado. Las
respuestas HTTP JSON de 64 KiB o más se decodifican con `compute` en un isolate;
las respuestas pequeñas evitan el coste de crear un isolate.

### Justificación para la sustentación

Las estrategias descritas aquí se agregaron para cubrir la implementación
asignada a Andrés Cáceres; no representan una implementación común ni un
requisito uniforme para todo el equipo. Cada desarrollador debe revisar su
alcance y agregar las estrategias que correspondan a sus propias necesidades.

| Grupo | Decisión que se puede explicar |
|---|---|
| Asincronía y concurrencia | Los repositorios y el arranque usan `Future` con `async`/`await`, `try/catch` y estados de carga. JSON de 64 KiB o más se decodifica con `compute` en un isolate; los cuerpos pequeños no pagan el coste de crear uno. |
| Conectividad eventual | `connectivity_plus` expone un `Stream`; al recuperar conexión se vuelven a cargar las vistas visibles y la telemetría pendiente de Hive se reintenta en orden, limitada a 200 eventos. Una respuesta offline nunca se etiqueta como dato vivo. |
| Almacenamiento local | Hive cubre KV, preferencias y cola; `flutter_secure_storage` protege la sesión; SQLite respalda historial relacional indexado por usuario/fecha; un archivo JSON en Application Support conserva la ubicación del carro. |
| Caché y privacidad | Hive conserva respuestas con hora de captura; `fromCache` permite distinguir datos offline de vivos. Un LRU en memoria está limitado a 32 entradas; el historial está particionado por usuario y ambos tipos de datos personales se eliminan al cerrar sesión. |

La app no carga imágenes remotas, por lo que no agrega una librería de caché
de imágenes. La analítica BQ8 se obtiene del backend y la base PostgreSQL
compartida; no se importa desde archivos ni se guarda una segunda base para el
dashboard.

## Design system

Fuentes: **Inter** (UI) y **DM Mono** (códigos, countdowns, timestamps) vía
`google_fonts`. Se descargan la primera vez con internet y quedan en caché.

Colores con significado fijo (nunca decorativos):

| Token | Hex | Uso |
|---|---|---|
| `Palette.primary` | `#0052CC` | Acciones, estados activos |
| `Palette.primarySoft` | `#DEEBFF` | Chips seleccionados, fondos tintados |
| `Palette.success` | `#36B37E` | Celdas libres, reserva confirmada |
| `Palette.warning` | `#FFAB00` | Poca disponibilidad, datos en caché |
| `Palette.danger` | `#DE350B` | Niveles llenos, destructivo |
| `Palette.secondary` | `#6554C0` | Flujo Find my car |
| `Palette.background` | `#F4F5F7` | Fondo de página |
| `Palette.surface` | `#FFFFFF` | Cards |
| `Palette.border` | `#EBECF0` | Separadores 1px |

Grid de 8px, touch target 48px, radio de card 8px, badge 3px, padding de
página 16px. Sin sombras: profundidad por cards blancas sobre fondo gris.
