class PetModel {
  final String id;
  final String name;
  final int price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;

  PetModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'],
      name: map['name'],
      price: map['price'] ?? 0,
      imageUrl: map['image_url'],
      description: map['description'],
      isAvailable: map['is_available'] ?? true,
    );
  }
}

class ChildPetModel {
  final String id;
  final String childId;
  final String petId;
  final int xp;
  final int level;
  final PetModel? pet;

  ChildPetModel({
    required this.id,
    required this.childId,
    required this.petId,
    this.xp = 0,
    this.level = 1,
    this.pet,
  });

  factory ChildPetModel.fromMap(Map<String, dynamic> map) {
    return ChildPetModel(
      id: map['id'],
      childId: map['child_id'],
      petId: map['pet_id'],
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      pet: map['pets'] != null ? PetModel.fromMap(map['pets']) : null,
    );
  }

  String get levelLabel {
    switch (level) {
      case 1: return 'Baby 🥚';
      case 2: return 'Growing 🐣';
      case 3: return 'Adult ⭐';
      default: return 'Baby 🥚';
    }
  }

  int get xpForNextLevel {
    switch (level) {
      case 1: return 100;
      case 2: return 300;
      default: return 300;
    }
  }

  bool get isMaxLevel => level >= 3;
}