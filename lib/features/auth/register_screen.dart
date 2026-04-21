import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/app_snackbar.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const int _minLength = 8;
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSymbol = RegExp(
    r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?/\\~`"'
    "'"
    r']',
  );

  String? _validatePassword(String password) {
    if (password.length < _minLength) {
      return 'Password must be at least $_minLength characters.';
    }
    if (!_hasLetter.hasMatch(password)) {
      return 'Password must include at least one letter.';
    }
    if (!_hasDigit.hasMatch(password)) {
      return 'Password must include at least one number.';
    }
    if (!_hasSymbol.hasMatch(password)) {
      return 'Password must include at least one symbol (e.g. @, #, !).';
    }
    return null;
  }

  int get _strengthScore {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= _minLength) score++;
    if (_hasLetter.hasMatch(p)) score++;
    if (_hasDigit.hasMatch(p)) score++;
    if (_hasSymbol.hasMatch(p)) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.green;
      default:
        return Colors.grey.shade300;
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong ✓';
      default:
        return '';
    }
  }

  Future<void> _register() async {
    final password = _passwordController.text.trim();

    if (_emailController.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Please enter your email.');
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      AppSnackbar.warning(context, passwordError);
      return;
    }

    if (password != _confirmController.text.trim()) {
      AppSnackbar.warning(context, 'Passwords do not match.');
      return;
    }

    if (_pinController.text.length != 4) {
      AppSnackbar.warning(context, 'PIN must be exactly 4 digits.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(_emailController.text.trim(), password);

      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client
          .from('profiles')
          .update({'pin': _pinController.text})
          .eq('id', userId);

      if (mounted) {
        AppSnackbar.success(context, 'Account created! Please log in.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Registration failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Register as Parent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to manage your children profiles.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  helperText:
                      'Min 8 chars · letter · number · symbol (e.g. @#!)',
                  helperMaxLines: 2,
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _strengthScore / 4,
                          color: _strengthColor,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _strengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Set Your Parent PIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'You will need this PIN to access the parent dashboard.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
