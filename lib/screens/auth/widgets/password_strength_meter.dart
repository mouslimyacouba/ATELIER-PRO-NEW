import 'package:flutter/material.dart';

import '../../../core/password_policy.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.email,
  });

  final String password;
  final String? email;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final strength = PasswordPolicy.strength(password, email: email);
    final suggestion = PasswordPolicy.suggestion(password, email: email);
    final bars = switch (strength) {
      PasswordStrength.strong => 3,
      PasswordStrength.medium => 2,
      _ => 1,
    };

    return Semantics(
      label: 'Solidité du mot de passe: ${switch (strength) {
        PasswordStrength.strong => 'forte',
        PasswordStrength.medium => 'moyenne',
        _ => 'faible',
      }}',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(3, (index) {
                  final active = index < bars;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 6,
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: active
                            ? switch (strength) {
                                PasswordStrength.strong => colors.tertiary,
                                PasswordStrength.medium => colors.secondary,
                                _ => colors.error,
                              }
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                suggestion ?? 'Mot de passe conforme.',
                style: TextStyle(
                  fontSize: 12,
                  color: suggestion == null
                      ? colors.tertiary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
