// =============================================================================
// LoginScreen — Schermata di autenticazione
// =============================================================================
//
// Permette all'utente di accedere con email + password o di continuare come
// ospite (senza autenticazione). La validazione è client-side; l'accettazione
// è automatica (nessun backend di autenticazione reale).
//
// Struttura visiva:
//   - Gradient background + video in loop (FullScreenVideo)
//   - Card centrata (480×580) con form email/password
//   - Bottone "Accedi" con gradiente brand via AppButton.primary()
//   - Link "Continua come ospite" via AppButton.text()
//   - Campo password con toggle visibilità (suffixIcon)
//
// Dopo l'accesso naviga a StartScreen (/start).
//
// Classe esportata: LoginScreen
// =============================================================================

import 'package:flutter/material.dart';
import '../utils/user_preferences.dart';
import '../widgets/full_screen_video.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_input.dart';
import '../widgets/common/app_spacing.dart';

/// Schermata di login con form email + password e accesso ospite.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci la tua email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Email non valida';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci la password';
    if (value.length < 6) return 'Almeno 6 caratteri';
    return null;
  }

  Future<void> _onLogin() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await UserPreferences.saveLoginState(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/start');
  }

  Future<void> _onGuest() async {
    setState(() => _isLoading = true);
    await UserPreferences.saveGuestState();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/start');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Sfondo sfumato brand
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B9D),
                  Color(0xFF00B8DB),
                  Color(0xFF4ECDC4),
                ],
              ),
            ),
          ),

          const Align(
            alignment: Alignment.center,
            child: FullScreenVideo(),
          ),

          Align(
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.black38,
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        width: 480,
                        height: 580,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl, vertical: 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/image/logo.png',
                                height: 80,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.menu_book_rounded,
                                  size: 80,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                'Bentornato su ApprenderAI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Accedi per continuare il tuo percorso',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              // Campo email
                              AppInput(
                                controller: _emailController,
                                label: 'Email',
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Campo password con toggle visibilità
                              AppInput(
                                controller: _passwordController,
                                label: 'Password',
                                validator: _validatePassword,
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xxl),
                              // Bottone Accedi — gradiente brand via AppButton.primary
                              AppButton.primary(
                                context,
                                label: 'Accedi',
                                onPressed: _isLoading ? null : _onLogin,
                                isLoading: _isLoading,
                                width: double.infinity,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Accesso ospite
                              AppButton.text(
                                context,
                                label: 'Continua come ospite',
                                onPressed: _isLoading ? null : _onGuest,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
