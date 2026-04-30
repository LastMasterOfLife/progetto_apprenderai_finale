// =============================================================================
// AppInput — Campo di testo standard del design system ApprenderAI
// =============================================================================
//
// Wrapper leggero attorno a [TextFormField] che delega tutta la stilizzazione
// all'[InputDecorationTheme] definito in AppTheme. Il widget aggiunge solo
// le opzioni di configurazione più comuni (label, validator, obscure, icone)
// senza duplicare stili hardcoded.
//
// In questo modo modificare lo stile degli input in tutta l'app richiede
// solo di cambiare AppTheme — non i singoli widget.
//
// Usato in: LoginScreen (email, password)
// =============================================================================

import 'package:flutter/material.dart';

/// Campo di input standard dell'app.
///
/// Esempio base:
/// ```dart
/// AppInput(
///   controller: _emailController,
///   label: 'Email',
///   keyboardType: TextInputType.emailAddress,
///   validator: _validateEmail,
///   prefixIcon: Icon(Icons.email_outlined),
/// )
/// ```
///
/// Esempio password con toggle visibilità:
/// ```dart
/// AppInput(
///   controller: _passwordController,
///   label: 'Password',
///   obscureText: _obscure,
///   prefixIcon: Icon(Icons.lock_outline),
///   suffixIcon: IconButton(
///     icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
///     onPressed: () => setState(() => _obscure = !_obscure),
///   ),
/// )
/// ```
class AppInput extends StatelessWidget {
  /// Controller del campo.
  final TextEditingController controller;

  /// Testo del label fluttuante.
  final String label;

  /// Funzione di validazione. Restituisce null se valido, stringa di errore
  /// altrimenti.
  final String? Function(String?)? validator;

  /// Tipo di tastiera da mostrare.
  final TextInputType keyboardType;

  /// Se true oscura il testo (per le password).
  final bool obscureText;

  /// Icona a sinistra del campo.
  final Widget? prefixIcon;

  /// Widget a destra del campo (es. IconButton per toggle password).
  final Widget? suffixIcon;

  /// Numero massimo di righe (default 1).
  final int? maxLines;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Tutto il resto viene dall'InputDecorationTheme in AppTheme
      ),
    );
  }
}
