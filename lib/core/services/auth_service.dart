import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  static Future<AuthResponse> register(String email, String password) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> logout() async {
    await supabase.auth.signOut();
  }

  static User? get currentUser => supabase.auth.currentUser;
  static bool get isLoggedIn => supabase.auth.currentUser != null;
  static bool get isAdmin =>
      supabase.auth.currentUser?.email == 'admin@kidsstudyapp.com';
}