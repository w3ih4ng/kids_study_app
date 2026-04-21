import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/child_model.dart';

final supabase = Supabase.instance.client;

class ChildService {
  static Future<List<ChildModel>> getChildren() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('children')
        .select()
        .eq('parent_id', userId)
        .order('created_at');
    return (response as List).map((e) => ChildModel.fromMap(e)).toList();
  }

  static Future<void> createChild(String nickname) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('children').insert({
      'parent_id': userId,
      'nickname': nickname,
    });
  }

  static Future<void> updateChild(String childId, String nickname) async {
    await supabase
        .from('children')
        .update({'nickname': nickname})
        .eq('id', childId);
  }

  static Future<void> deleteChild(String childId) async {
    await supabase.from('children').delete().eq('id', childId);
  }

  static Future<String> getParentPin() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('profiles')
        .select('pin')
        .eq('id', userId)
        .single();
    return response['pin'] ?? '1234';
  }

  static Future<void> updatePin(String newPin) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'pin': newPin}).eq('id', userId);
  }

  static Future<void> saveLastActiveChild(String childId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'last_active_child_id': childId})
        .eq('id', userId);
  }

  static Future<String?> getLastActiveChildId() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await Supabase.instance.client
        .from('profiles')
        .select('last_active_child_id')
        .eq('id', userId)
        .single();
    return response['last_active_child_id'] as String?;
  }
}
