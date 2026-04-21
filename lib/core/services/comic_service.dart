import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comic_model.dart';

final supabase = Supabase.instance.client;

class ComicService {
  static Future<List<ComicModel>> getComics() async {
    final response = await supabase
        .from('comics')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => ComicModel.fromMap(e)).toList();
  }

  static Future<void> createComic({
    required String title,
    String? author,
    String? description,
    String? coverUrl,
    String? pdfUrl,
  }) async {
    await supabase.from('comics').insert({
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'pdf_url': pdfUrl,
    });
  }

  static Future<void> updateComic(String id, Map<String, dynamic> data) async {
    await supabase.from('comics').update(data).eq('id', id);
  }

  static Future<void> deleteComic(String id) async {
    await supabase.from('comics').delete().eq('id', id);
  }
}
