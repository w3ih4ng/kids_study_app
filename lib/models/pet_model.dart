class PetModel {
  final String id;
  final String name;
  final int price;
  final String? imageUrl;
  final String? description;
  final String? soundUrl;
  final bool isAvailable;

  PetModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.soundUrl,
    this.isAvailable = true,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'],
      name: map['name'],
      price: map['price'] ?? 0,
      imageUrl: map['image_url'],
      description: map['description'],
      soundUrl: map['sound_url'],
      isAvailable: map['is_available'] ?? true,
    );
  }
}

class ChildPetModel {
  final String id;
  final String childId;
  final String petId;
  final PetModel? pet;

  ChildPetModel({
    required this.id,
    required this.childId,
    required this.petId,
    this.pet,
  });

  factory ChildPetModel.fromMap(Map<String, dynamic> map) {
    return ChildPetModel(
      id: map['id'],
      childId: map['child_id'],
      petId: map['pet_id'],
      pet: map['pets'] != null ? PetModel.fromMap(map['pets']) : null,
    );
  }
}