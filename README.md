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

## Git

- Rama por pantalla: `feature/home`, `feature/find-my-car`, etc., desde `develop`.
- PR hacia `develop`. Solo tocar tu carpeta de pantalla (y `core/` si agregas
  un token o componente compartido, avisando en el grupo).

## Arquitectura 

```
lib/
├── main.dart
├── app/                        
│   ├── parkwise_app.dart       
│   └── app_router.dart         
│
├── core/                        
│   ├── design/                 
│   └── widgets/                 
│
├── domain/                      
│   ├── entities/                
│   └── ports/                 
│
├── infrastructure/              
│   └── mock/                    
│
└── presentation/                
    ├── root/root_screen.dart    
    └── screens/                 
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
