# ParkWise (Flutter · Android)

App de parqueaderos del campus (Universidad de los Andes). Este repo es la
versión Android en Flutter. La app iOS (SwiftUI) usa el mismo backend
(`Moviles-Backend`), así que una reserva hecha en una se ve en la otra.

El contrato de la API está en `../Moviles-Backend/docs/API.md`.

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

Las pruebas no llaman al backend. Usan los mocks de `lib/infrastructure/mock/`
y `AppDependencies.mock()` para las pantallas, un `MockClient` de
`package:http/testing.dart` para los repositorios HTTP y `sqflite_common_ffi`
con una base temporal para SQLite. Los archivos están en `test/` y todos
terminan en `_test.dart`.

| Tema | Archivos |
|---|---|
| Red y caché | `api_client`, `circuit_breaker`, `http_parking_repository`, `local_cache_lru`, `lru_cache`, `cached_nearby_lot_repository`, `telemetry_client` |
| Almacenamiento local | `local_database`, `local_persistence`, `device_preferences_store`, `reservation_history_offline` |
| Login y Register | `auth_view_model`, `auth_offline_and_draft`, `register_rules` |
| Home, mapa y pronóstico | `home_view_model`, `level_map_view_model`, `parking_entities`, `spot_cell` |
| Find a spot y Reserve | `find_spot_view_model`, `spot_ranking`, `recommend_spot`, `reserve_view_model`, `reserve_offline`, `reserve_funnel`, `outbox_reservation_repository` |
| No campus spots, Find my car, Offline y Profile | `no_spots_view_model`, `lot_arrival_view_model`, `lot_photo`, `find_my_car_view_model`, `offline_and_profile` |
| Todas las pantallas | `screens_smoke`: cada pantalla a 390 px y 320 px de ancho sin overflow |

## Arquitectura

Hexagonal (puertos y adaptadores) con MVVM en la presentación:

```
lib/
├── main.dart                    crea las dependencias y arranca la app
├── app/
│   ├── dependencies.dart        arma adaptadores y view models (MultiProvider)
│   ├── parkwise_app.dart        MaterialApp + tema
│   └── app_router.dart          rutas de las pantallas que se abren encima
├── core/
│   ├── cache/                   LruCache y caché de fotos de los parqueaderos
│   ├── config/                  API_BASE_URL
│   ├── design/                  palette, typography, spacing, app_theme
│   ├── widgets/                 componentes reutilizables
│   └── format.dart              fechas, horas y cuenta regresiva
├── domain/                      Dart puro, sin Flutter ni paquetes
│   ├── entities/                ParkingLevel, ParkingSpot, Reservation, PendingAction, ...
│   ├── ports/                   interfaces que implementa infrastructure
│   ├── services/                recommendSpot, rankSpots, RegisterRules
│   └── errors.dart              ApiException, NetworkException, CircuitOpenException
├── infrastructure/              implementaciones de los puertos
│   ├── http/                    ApiClient, CircuitBreaker, repositorios, outbox, TelemetryClient
│   ├── device/                  geolocator, connectivity_plus, device_info_plus, url_launcher
│   ├── storage/                 sesión, Hive, SQLite, shared_preferences y archivos
│   └── mock/                    datos de prueba para AppDependencies.mock()
└── presentation/
    ├── shell/                   AuthGate (login o app) y MainShell (tabs)
    ├── shared/                  manejo de red, mensajes de error y avisos comunes
    └── screens/<pantalla>/      <pantalla>_screen.dart + <pantalla>_view_model.dart
```

Regla de dependencias: `presentation → domain ← infrastructure`. Los view
models solo usan las interfaces de `domain/ports`, y las pantallas solo
escuchan su `ChangeNotifier` con `provider`: no hacen HTTP, ni tocan Hive,
SQLite ni el GPS. Solo `app/dependencies.dart` conoce las implementaciones
concretas.

### Almacenamiento local

| Dónde | Qué |
|---|---|
| `flutter_secure_storage` | Token y usuario. El token nunca va a Hive, a SQLite ni a los logs |
| Hive `cache` | Última respuesta de niveles, puestos por nivel, edificios y reserva abierta |
| Hive `prefs` | Edificio destino |
| Hive `telemetry` | Cola de eventos pendientes (máx. 200), cada uno con su hora original |
| Hive `drafts` | Borrador de Register: nombre y correo, nunca la contraseña |
| `shared_preferences` | Hora de llegada y último nivel abierto |
| SQLite `parkwise_local.db`, `reservation_history` | Historial de reservas por cuenta, para ver Reserve y Profile sin señal |
| SQLite, `pending_actions` | Cola de "I parked" e "I left" hechos sin señal |
| SQLite, `nearby_lots` | Parqueaderos cercanos, válidos por 24 horas |
| SQLite, `lot_redirects` | Redirecciones de Navigate que esperan la pregunta "Did you park at ...?" |
| `parked_vehicle.json` en Application Support | Última ubicación del carro |
| `forecast.json` en Application Support | Pronóstico de la fecha de llegada, para calcular el nivel recomendado sin señal |
| Caché `lot_photos` (`flutter_cache_manager`) | Fotos de los parqueaderos, 30 días y máximo 20 archivos |

Hay una sola base SQLite, `LocalDatabase`, en la versión 3. Cada versión crea
sus tablas en `onUpgrade`, así un celular que tenía la app anterior conserva
su historial. El historial tiene `user_id` en la llave: una cuenta nunca ve el
de otra. Los dos archivos JSON se escriben primero en un `.tmp` y después se
renombran, así un corte nunca deja medio archivo. Al cerrar sesión se borran
la sesión, la caché, el historial, la ubicación del carro, la cola y las
redirecciones.

`LocalCache` guarda en memoria hasta 32 respuestas ya decodificadas, encima de
Hive. Las respuestas JSON de 4 KiB o más se decodifican con `compute` en otro
isolate. Los eventos de analítica salen por `TelemetryClient` y, si no hay
señal, esperan en la cola de Hive hasta que vuelva.

## Estrategias del Sprint 3 por integrante

**Andrés Cáceres** · Home, Level map, Forecast, Accessible y EV spots

- El pronóstico de la fecha de llegada se guarda en `forecast.json` y el nivel
  recomendado se calcula en el teléfono, así cambiar la hora funciona sin señal.
- Home descarga P1, P2 y P3 a la vez con `Future.wait`. Si un nivel falla, los
  otros siguen.
- El refresco del mapa cada 5 s se pausa sin señal y sigue al volver. En el
  mapa, el chip del último nivel abierto se marca con `*`.
- Historial en SQLite por cuenta, LRU de `LocalCache` y `compute` para JSON
  grandes.

**Rodrigo García** · Find a spot, Reserve, Login y Register

- "I parked" e "I left" sin señal van a la tabla `pending_actions` y se mandan
  solos al volver la conexión. `flush()` comparte un solo envío aunque lo pidan
  varias veces a la vez.
- La cola publica su estado en un `Stream` que escuchan Reserve, Find my car,
  Profile y Offline.
- Find a spot ordena los puestos con `Isolate.run` y guarda 16 combinaciones de
  filtros por 30 s en una `LruCache`. La búsqueda espera 150 ms después de la
  última letra.
- Login apaga el botón sin señal y lo prende solo al volver. Register guarda
  nombre y correo en Hive y revisa el formulario con `RegisterRules`, las
  mismas reglas del backend.

**Fabio Higuera** · No campus spots, Find my car, Offline y Profile

- Parqueaderos cercanos en SQLite por 24 horas, con sus fotos en caché por 30
  días.
- Notify me revisa el campus cada 30 s y se pausa sin señal.
- Navigate guarda la redirección en `lot_redirects` y la pregunta "Did you park
  at ...?" se puede responder sin señal.
- Find my car usa el GPS sin datos y no borra el carro mientras su check-in
  siga en la cola.
- La vista Offline junta todo lo guardado y se cierra sola al volver la señal.
  Profile pregunta antes de cerrar sesión si hay acciones en la cola.

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
