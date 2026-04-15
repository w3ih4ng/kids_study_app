import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/pet_model.dart';

final supabase = Supabase.instance.client;

class PetService {
  // ── Shop ──────────────────────────────────────────

  static Future<List<PetModel>> getAllPets() async {
    final response = await supabase
        .from('pets')
        .select()
        .eq('is_available', true)
        .order('price');
    return (response as List).map((e) => PetModel.fromMap(e)).toList();
  }

  // ── Child Pets ────────────────────────────────────

  static Future<List<ChildPetModel>> getChildPets(String childId) async {
    final response = await supabase
        .from('child_pets')
        .select('*, pets(*)')
        .eq('child_id', childId);
    return (response as List)
        .map((e) => ChildPetModel.fromMap(e))
        .toList();
  }

  static Future<bool> childOwnsPet(
      String childId, String petId) async {
    final response = await supabase
        .from('child_pets')
        .select()
        .eq('child_id', childId)
        .eq('pet_id', petId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  static Future<void> buyPet({
    required String childId,
    required String petId,
    required int price,
  }) async {
    // Deduct coins
    await supabase.rpc('deduct_coins', params: {
      'child_id_input': childId,
      'coins_input': price,
    });

    // Add pet to child
    await supabase.from('child_pets').insert({
      'child_id': childId,
      'pet_id': petId,
      'xp': 0,
      'level': 1,
    });
  }

  // Set active pet
  static Future<void> setActivePet({
    required String childId,
    required String petId,
  }) async {
    await supabase
        .from('children')
        .update({'active_pet_id': petId})
        .eq('id', childId);
  }

  // Add XP to active pet when quiz completed
  static Future<void> addXp({
    required String childId,
    required String petId,
    required int xpToAdd,
  }) async {
    // Get current XP
    final response = await supabase
        .from('child_pets')
        .select('xp, level')
        .eq('child_id', childId)
        .eq('pet_id', petId)
        .single();

    final currentXp = (response['xp'] ?? 0) + xpToAdd;
    int newLevel = response['level'] ?? 1;

    // Level up logic
    if (currentXp >= 300) {
      newLevel = 3;
    } else if (currentXp >= 100) {
      newLevel = 2;
    }

    await supabase
        .from('child_pets')
        .update({'xp': currentXp, 'level': newLevel})
        .eq('child_id', childId)
        .eq('pet_id', petId);
  }

  // ── Admin ─────────────────────────────────────────

  static Future<void> createPet({
    required String name,
    required int price,
    String? imageUrl,
    String? description,
  }) async {
    await supabase.from('pets').insert({
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'description': description,
    });
  }

  static Future<void> updatePet(
      String id, Map<String, dynamic> data) async {
    await supabase.from('pets').update(data).eq('id', id);
  }

  static Future<void> deletePet(String id) async {
    await supabase.from('pets').delete().eq('id', id);
  }
}