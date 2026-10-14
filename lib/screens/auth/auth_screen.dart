import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/contact_actions.dart';
import '../../core/password_policy.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_dialog.dart';
import 'widgets/auth_segmented_control.dart';
import 'widgets/password_strength_meter.dart';

enum _AuthMethod { email, phone }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMethod _method = _AuthMethod.email;
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _acceptedPolicies = false;
  bool _passwordVisible = false;
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_refreshForm);
    _passwordCtrl.addListener(_refreshForm);
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ---------- Email ----------

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && !_acceptedPolicies) {
      setState(() => _error =
          'Acceptez les conditions et la politique de confidentialité pour continuer.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    if (_isSignUp) {
      final signUpError = await auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (signUpError != null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = signUpError;
          });
        }
        return;
      }

      final verificationError = await auth.sendEmailVerification();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = verificationError;
      });
      return;
    }

    final result = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result;
    });
  }

  // ---------- Téléphone ----------

  Future<void> _sendPhoneCode() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entre ton numéro de téléphone.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final phone = normalizePhone(_phoneCtrl.text.trim());
    final error = await context.read<AuthProvider>().sendPhoneCode(
      phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _loading = false;
        });
      },
      onAutoVerified: (result) {
        // Certains Android valident automatiquement sans code (SMS
        // Retriever) — dans ce cas on saute directement à la connexion.
        if (!mounted) return;
        final (autoError, _) = result;
        setState(() => _loading = false);
        if (autoError == null) {
          context.go('/');
        } else {
          setState(() => _error = autoError);
        }
      },
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _confirmPhoneCode() async {
    if (_codeCtrl.text.trim().length < 6) {
      setState(() => _error = 'Entre le code à 6 chiffres reçu par SMS.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final (error, _) = await context
        .read<AuthProvider>()
        .confirmPhoneCode(_codeCtrl.text.trim());
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    // Nouveau compte ou ancien, dans les deux cas : navigation explicite.
    // Si nouveau (pas d'atelier), le routeur redirige automatiquement vers
    // l'onboarding — pas besoin de dupliquer le formulaire atelier ici.
    setState(() => _loading = false);
    if (mounted) context.go('/');
  }

  // ---------- Google ----------

  Future<void> _submitGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final (error, _) = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    setState(() => _loading = false);
    context.go('/');
  }

  Future<void> _forgotPassword() async {
    showForgotPasswordDialog(context, initialEmail: _emailCtrl.text.trim());
  }

  void _setSignUp(bool value) {
    setState(() {
      _isSignUp = value;
      _method = _AuthMethod.email;
      _acceptedPolicies = false;
      _error = null;
    });
  }

  Future<void> _openLegalPage(String path) async {
    await context.push(path);
  }

  Widget _buildBrandHeader() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AtelierPro',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text(
                'Le carnet de commandes de votre atelier',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyConsent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptedPolicies,
          onChanged: _loading
              ? null
              : (value) => setState(() => _acceptedPolicies = value ?? false),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('J’accepte les '),
                _LegalLink(
                  label: 'conditions d’utilisation',
                  onTap: () => _openLegalPage('/conditions'),
                ),
                const Text(' et la '),
                _LegalLink(
                  label: 'politique de confidentialité',
                  onTap: () => _openLegalPage('/confidentialite'),
                ),
                const Text('.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSection({required bool signingUp}) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: TextStyle(color: colors.onSurfaceVariant)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
          ),
          onPressed: _loading ? null : _submitGoogle,
          child: Text(
            signingUp ? "S'inscrire avec Google" : 'Continuer avec Google',
          ),
        ),
        if (signingUp) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('En continuant avec Google, vous acceptez les '),
              _LegalLink(
                label: "conditions d'utilisation",
                onTap: () => _openLegalPage('/conditions'),
              ),
              const Text(' et la '),
              _LegalLink(
                label: 'politique de confidentialité',
                onTap: () => _openLegalPage('/confidentialite'),
              ),
              const Text('.'),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 40
                      ? constraints.maxHeight - 52
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: 16),
                        AuthSegmentedControl(
                          selected: _isSignUp,
                          onSignInTap: () => _setSignUp(false),
                          onSignUpTap: () => _setSignUp(true),
                        ),
                        if (!_isSignUp) ...[
                          const SizedBox(height: 18),
                          Text(
                            _method == _AuthMethod.email
                                ? 'Bon retour parmi nous'
                                : 'Connexion par téléphone',
                            style: const TextStyle(
                              fontSize: 25,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildMethodSelector(),
                        ] else ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Ouvrez votre compte',
                            style: TextStyle(
                              fontSize: 25,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: _isSignUp || _method == _AuthMethod.email
                              ? _buildEmailForm()
                              : _buildPhoneForm(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        if (!_isSignUp) ...[
                          _buildGoogleSection(signingUp: false),
                          const SizedBox(height: 32),
                          _buildSecurityNote(),
                        ] else ...[
                          const SizedBox(height: 16),
                          _buildGoogleSection(signingUp: true),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        _MethodChoice(
          label: 'E-mail',
          selected: _method == _AuthMethod.email,
          onTap: () => setState(() {
            _method = _AuthMethod.email;
            _error = null;
          }),
        ),
        const SizedBox(width: 8),
        _MethodChoice(
          label: 'Téléphone',
          selected: _method == _AuthMethod.phone,
          onTap: () => setState(() {
            _method = _AuthMethod.phone;
            _error = null;
          }),
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: colors.tertiary),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Connexion protégée. Après plusieurs essais échoués, l'accès est suspendu quelques minutes pour protéger votre compte.",
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Adresse e-mail'),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'vous@exemple.com',
          ),
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return 'Entrez votre adresse e-mail.';
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(value)) {
              return 'Adresse e-mail invalide.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _fieldLabel('Mot de passe'),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: !_passwordVisible,
          textInputAction:
              _isSignUp ? TextInputAction.next : TextInputAction.done,
          autofillHints: _isSignUp
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: _isSignUp ? '8 caractères minimum' : 'Votre mot de passe',
            suffixIcon: TextButton(
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              child: Text(_passwordVisible ? 'Masquer' : 'Afficher'),
            ),
          ),
          validator: (v) {
            final value = v ?? '';
            if (value.isEmpty) return 'Entrez votre mot de passe.';
            if (_isSignUp) {
              final error =
                  PasswordPolicy.validate(value, email: _emailCtrl.text.trim());
              return error ?? null;
            }
            return null;
          },
        ),
        if (_isSignUp)
          PasswordStrengthMeter(
            password: _passwordCtrl.text,
            email: _emailCtrl.text.trim(),
          ),
        if (!_isSignUp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size(44, 44),
              ),
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
        if (_isSignUp) ...[
          const SizedBox(height: 16),
          _fieldLabel('Confirmer le mot de passe'),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              hintText: 'Retapez le mot de passe',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirmez votre mot de passe.';
              }
              if (value != _passwordCtrl.text) {
                return 'Les mots de passe ne correspondent pas.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          _buildPolicyConsent(),
          if (!_acceptedPolicies)
            Padding(
              padding: EdgeInsets.only(left: 12, top: 2),
              child: Text(
                'Cochez la case pour créer votre compte.',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading || (_isSignUp && !_acceptedPolicies)
              ? null
              : _submitEmail,
          child: _loading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
              : Text(_isSignUp ? 'Créer mon compte' : 'Se connecter'),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 44),
          Text(
            'Un e-mail de confirmation vous sera envoyé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _buildPhoneForm() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _codeSent ? 'Code reçu par SMS' : 'Connexion par téléphone',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _codeSent
              ? 'Entre le code à 6 chiffres envoyé au ${normalizePhone(_phoneCtrl.text.trim())}'
              : 'Compte créé automatiquement à la première connexion',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (!_codeSent) ...[
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '90 12 34 56',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _sendPhoneCode,
            child: _loading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : const Text('Recevoir le code par SMS'),
          ),
        ] else ...[
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8),
            maxLength: 6,
            decoration:
                const InputDecoration(counterText: '', hintText: '••••••'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _confirmPhoneCode,
            child: _loading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : const Text('Vérifier le code'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _codeSent = false;
                      _codeCtrl.clear();
                      _error = null;
                    }),
            child: const Text('Modifier le numéro / renvoyer le code'),
          ),
        ],
      ],
    );
  }
}

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: colors.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
