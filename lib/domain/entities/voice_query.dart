import 'spot_filter.dart';

class VoiceQuery {
  const VoiceQuery({
    this.levelCode,
    this.zone,
    this.spotNumber,
    this.filters = const {SpotFilter.available},
  });

  static const empty = VoiceQuery();

  final String? levelCode;
  final String? zone;
  final int? spotNumber;
  final Set<SpotFilter> filters;

  String? get spotCode {
    final zone = this.zone;
    final number = spotNumber;
    if (zone == null || number == null) return null;
    return '$zone-${number.toString().padLeft(2, '0')}';
  }

  bool get understood =>
      levelCode != null ||
      zone != null ||
      filters.any((filter) => filter != SpotFilter.available);

  String get searchText => [?levelCode, ?zone, ?spotCode].join(' ');
}
