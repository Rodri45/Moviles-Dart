// un edificio destino, se usa para calcular los minutos a pie
class Building {
  const Building({required this.id, required this.name});

  factory Building.fromJson(Map<String, dynamic> json) =>
      Building(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
