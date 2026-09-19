/// Estado de una celda individual de parqueo.
enum SpotState { free, occupied, reserved, disabled }

/// Una celda de parqueo (ej. "A-12").
class ParkingSpot {
  const ParkingSpot({
    required this.id,
    required this.code,
    required this.state,
    this.isAccessible = false,
    this.isEv = false,
  });

  final String id;

  /// Código visible en la celda, ej. "A-12".
  final String code;
  final SpotState state;

  /// Celda para personas con movilidad reducida.
  final bool isAccessible;

  /// Celda con cargador para vehículo eléctrico.
  final bool isEv;
}
