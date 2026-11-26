import 'parking_spot.dart';

enum ReportKind {
  occupied('occupied', 'Occupied without a reservation'),
  blocked('blocked', 'Spot blocked'),
  damaged('damaged', 'Sign or paint damaged'),
  other('other', 'Something else');

  const ReportKind(this.code, this.label);

  final String code;
  final String label;

  static ReportKind fromCode(String? code) =>
      values.firstWhere((kind) => kind.code == code, orElse: () => other);
}

enum ReportState { waiting, sending, sent, rejected }

class SpotReport {
  const SpotReport({
    required this.clientId,
    required this.spotId,
    required this.levelCode,
    required this.kind,
    required this.shownStatus,
    required this.reportedAt,
    this.note,
    this.id,
    this.photoUrl,
    this.photoPath,
    this.state = ReportState.waiting,
  });

  factory SpotReport.fromJson(
    Map<String, dynamic> json, {
    String? imageBase,
  }) {
    final photo = json['photoUrl'] as String?;
    return SpotReport(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      spotId: json['spotId'] as String,
      levelCode: json['levelCode'] as String,
      kind: ReportKind.fromCode(json['kind'] as String?),
      shownStatus:
          SpotStatus.values.asNameMap()[json['shownStatus']] ?? SpotStatus.free,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      note: json['note'] as String?,
      photoUrl: photo == null || imageBase == null
          ? photo
          : Uri.parse(imageBase).resolve(photo).toString(),
      state: ReportState.sent,
    );
  }

  final String clientId;
  final String spotId;
  final String levelCode;
  final ReportKind kind;
  final SpotStatus shownStatus;
  final DateTime reportedAt;
  final String? note;
  final String? id;
  final String? photoUrl;
  final String? photoPath;
  final ReportState state;

  bool get hasPhoto => photoUrl != null || photoPath != null;

  SpotReport withState(ReportState state) => SpotReport(
    clientId: clientId,
    spotId: spotId,
    levelCode: levelCode,
    kind: kind,
    shownStatus: shownStatus,
    reportedAt: reportedAt,
    note: note,
    id: id,
    photoUrl: photoUrl,
    photoPath: photoPath,
    state: state,
  );

  Map<String, Object> toJson({String? photo}) => {
    'clientId': clientId,
    'spotId': spotId,
    'kind': kind.code,
    'shownStatus': shownStatus.name,
    'reportedAt': reportedAt.toUtc().toIso8601String(),
    'note': ?note,
    'photo': ?photo,
  };
}
