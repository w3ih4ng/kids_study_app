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
    List<String> pages = const [],
  }) async {
    await supabase.from('comics').insert({
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'pages': pages,
    });
  }

  static Future<void> updateComic(
      String id, Map<String, dynamic> data) async {
    await supabase.from('comics').update(data).eq('id', id);
  }

  static Future<void> addPage({
    required String comicId,
    required String pageUrl,
    required List<String> currentPages,
  }) async {
    final updatedPages = [...currentPages, pageUrl];
    await supabase
        .from('comics')
        .update({'pages': updatedPages})
        .eq('id', comicId);
  }

  static Future<void> removePage({
    required String comicId,
    required int pageIndex,
    required List<String> currentPages,
  }) async {
    final updatedPages = List<String>.from(currentPages)
      ..removeAt(pageIndex);
    await supabase
        .from('comics')
        .update({'pages': updatedPages})
        .eq('id', comicId);
  }

  static Future<void> deleteComic(String id) async {
    await supabase.from('comics').delete().eq('id', id);
  }
}