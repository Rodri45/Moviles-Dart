# ParkWise (Flutter · Android)

App de parqueaderos del campus (Universidad de los Andes). Este repo es la
versión Flutter; el subgrupo de Swift tiene la misma estructura.

**Por ahora solo hacemos la parte visual.** Nada de lógica, estado ni backend:
las pantallas muestran datos escritos a mano y los botones no hacen nada.

## Correr la app

Requisitos: Flutter 3.47+ (`flutter doctor` sin errores en "Android toolchain").

```bash
git clone <url-del-repo>
cd Moviles-Dart
flutter pub get
flutter run
```

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

### Mientras corre

| Tecla | Acción |
|---|---|
| `r` | Hot reload: ves tu cambio en el celular al instante |
| `R` | Reinicio completo |
| `q` | Cerrar |

Al abrir la app sale el **RootScreen**: una barra oscura arriba con flechas
◀ ▶ para pasar entre las 7 pantallas (muestra el nombre y `3 / 7`). Navega
hasta la tuya para verla.

## Estado de las pantallas

| # | Pantalla | Archivo | Estado |
|---|---|---|---|
| 1 | Home | `screens/home/home_screen.dart` | Pendiente |
| 2 | P1 · North | `screens/lot_detail/lot_detail_screen.dart` | Pendiente |
| 3 | Find a spot | `screens/find_spot/find_spot_screen.dart` | ✅ Hecha (referencia) |
| 4 | Reserve | `screens/reserve/reserve_screen.dart` | ✅ Hecha (referencia) |
| 5 | No campus spots | `screens/no_spots/no_spots_screen.dart` | Pendiente |
| 6 | Find my car | `screens/find_my_car/find_my_car_screen.dart` | Pendiente |
| 7 | Offline | `screens/offline/offline_screen.dart` | Pendiente |

Todas están en `lib/presentation/screens/`.

## Cómo hacer tu pantalla (paso a paso)

Usa `find_spot_screen.dart` y `reserve_screen.dart` como plantilla: copia su
estructura.

1. **Abre tu archivo** `lib/presentation/screens/<pantalla>/<pantalla>_screen.dart`.
   Arriba de la clase hay un comentario con lo que muestra Figma.
2. **Datos de ejemplo**: escríbelos como `const` privados arriba del archivo
   (mira `_spots` en Find a spot o `_history` en Reserve). No uses `domain/`
   ni `infrastructure/` por ahora.
3. **Layout**: reemplaza `ScreenPlaceholder` por el diseño real.
   - `Scaffold` con `backgroundColor: Palette.background`.
   - Contenido dentro de un `ListView` para que haga scroll.
   - `bottomNavigationBar: AppTabBar(current: AppTab.xxx)` si tu pantalla
     tiene la barra de abajo.
4. **Sub-widgets privados** (`_Header`, `_MiCard`, ...) en el mismo archivo.
   Si un widget se repite en 2+ pantallas, muévelo a `lib/core/widgets/`.
5. **Colores, fuentes y espaciados**: SOLO desde `lib/core/design/`.
   - `Palette.primary`, `Palette.success`, `Palette.warningSoft`, ...
   - `AppTypography.display / heading1 / heading2 / body / caption / overline /
     monoId / monoData / monoDisplay`
   - `Spacing.xs/sm/md/lg/xl`, `Radii.card/sm/badge`
   - Si te falta un color o estilo, agrégalo ahí (no lo hardcodees en tu pantalla).
6. **Componentes ya hechos** en `lib/core/widgets/`: `Pill`, `AppTabBar`,
   `StatusBadge`, `LevelCard`, `ForecastCard`, `SpotCell`, `PwScaffold`.
7. **Botones**: `onPressed: () {}`. Sin navegación ni estado.
8. **Responsive**: nada de anchos fijos grandes; usa `Expanded`/`Flexible`,
   y `maxLines: 1, overflow: TextOverflow.ellipsis` en textos que puedan crecer.
9. **Agrega tu pantalla al test** en `test/screens_smoke_test.dart` (mapa
   `screens`). Renderiza a 390px y 320px de ancho y falla si algo desborda.
10. Antes del PR:
    ```bash
    flutter analyze   # sin errores
    flutter test      # todo en verde
    ```

## Git

- Rama por pantalla: `feature/home`, `feature/find-my-car`, etc., desde `develop`.
- PR hacia `develop`. Solo tocar tu carpeta de pantalla (y `core/` si agregas
  un token o componente compartido, avisando en el grupo).

## Arquitectura (hexagonal)

```
lib/
├── main.dart
├── app/                         ← arranque
│   ├── parkwise_app.dart        MaterialApp + tema
│   └── app_router.dart          rutas con nombre
│
├── core/                        ← compartido, sin lógica de negocio
│   ├── design/                  palette, typography, spacing, app_theme
│   └── widgets/                 componentes reutilizables
│
├── domain/                      ← CENTRO DEL HEXÁGONO (Dart puro, sin Flutter)
│   ├── entities/                ParkingLot, ParkingLevel, ParkingSpot, ...
│   └── ports/                   interfaces (ParkingRepository, ...)
│
├── infrastructure/              ← ADAPTADORES (implementan los puertos)
│   └── mock/                    datos y repositorios de prueba
│
└── presentation/                ← UI
    ├── root/root_screen.dart    barra de pills + pantalla activa
    └── screens/                 una carpeta por pantalla
```

Regla de dependencias: `presentation → domain ← infrastructure`.
`domain/` no importa Flutter ni `infrastructure/`. Cuando exista backend se
agrega `infrastructure/http/` implementando los mismos puertos y las pantallas
no cambian. **En esta fase visual, `domain/` e `infrastructure/` no se tocan.**

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
