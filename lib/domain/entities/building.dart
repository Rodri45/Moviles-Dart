class Building {
  const Building({required this.id, required this.name, this.imageUrl});

  factory Building.fromJson(Map<String, dynamic> json, {String? imageBase}) {
    final image = json['imageUrl'] as String?;
    return Building(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: image == null || imageBase == null
          ? image
          : Uri.parse(imageBase).resolve(image).toString(),
    );
  }

  final String id;
  final String name;
  final String? imageUrl;
}
