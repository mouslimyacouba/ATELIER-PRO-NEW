import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Boîte de dialogue « Mot de passe oublié ».
/// Le message de succès ne confirme pas l'existence du compte : il est
/// identique que l'adresse soit connue ou non (anti-énumération).
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);

    final error =
        await auth.resetPasswordForEmail(_emailCtrl.text.trim().toLowerCase());
    if (!mounted) return;

    if (error != null) {
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
      return;
    }
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.lock_reset_outlined, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mot de passe oublié',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: _sent ? _buildSent() : _buildForm(),
      actions: _sent
          ? [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 48)),
                child: _sending
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Text('Envoyer le lien'),
              ),
            ],
    );
  }

  Widget _buildSent() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colors.tertiary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined,
              color: colors.onTertiaryContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Si un compte existe pour ${_emailCtrl.text.trim()}, un e-mail "
              "de réinitialisation vient d'être envoyé.\n\n"
              'Pensez à vérifier vos courriers indésirables.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Entrez votre adresse e-mail : nous vous enverrons un lien pour "
            'choisir un nouveau mot de passe.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            autofocus: _emailCtrl.text.isEmpty,
            onFieldSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Entrez votre adresse e-mail.';
              if (!_emailPattern.hasMatch(s)) return 'Adresse e-mail invalide.';
              return null;
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
