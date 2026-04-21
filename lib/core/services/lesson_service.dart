import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lesson_model.dart';

final supabase = Supabase.instance.client;

class LessonService {
  static Future<List<LessonModel>> getLessons({String? subject}) async {
    final response = subject != null
        ? await supabase
              .from('lessons')
              .select()
              .eq('subject', subject)
              .order('created_at', ascending: false)
        : await supabase
              .from('lessons')
              .select()
              .order('created_at', ascending: false);

    return (response as List).map((e) => LessonModel.fromMap(e)).toList();
  }

  static Future<void> createLesson({
    required String title,
    required String subject,
    required String difficulty,
    required String type,
    String? contentUrl,
    String? description,
    String ageLevel = '6+',
  }) async {
    await supabase.from('lessons').insert({
      'title': title,
      'subject': subject,
      'difficulty': difficulty,
      'type': type,
      'content_url': contentUrl,
      'description': description,
      'age_level': ageLevel,
    });
  }

  static Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    await supabase.from('lessons').update(data).eq('id', id);
  }

  static Future<void> deleteLesson(String id) async {
    await supabase.from('lessons').delete().eq('id', id);
  }
}
