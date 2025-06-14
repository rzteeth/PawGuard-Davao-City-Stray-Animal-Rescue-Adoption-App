// pet_model.dart
class Pet {
  final String id;
  final String name;
  final String species;
  final String activityLevel;
  final String size;
  final String imageUrl;
  final String description;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.activityLevel,
    required this.size,
    required this.imageUrl,
    required this.description,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      activityLevel: map['activityLevel'],
      size: map['size'],
      imageUrl: map['imageUrl'],
      description: map['description'],
    );
  }
}
