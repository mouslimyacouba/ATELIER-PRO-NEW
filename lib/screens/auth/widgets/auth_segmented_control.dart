import 'package:flutter/material.dart';

class AuthSegmentedControl extends StatelessWidget {
  const AuthSegmentedControl({
    super.key,
    required this.selected,
    required this.onSignInTap,
    required this.onSignUpTap,
  });

  final bool selected;
  final VoidCallback onSignInTap;
  final VoidCallback onSignUpTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTab(
              label: 'Se connecter',
              selected: !selected,
              onTap: onSignInTap,
            ),
          ),
          Expanded(
            child: _AuthTab(
              label: 'Créer un compte',
              selected: selected,
              onTap: onSignUpTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
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
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: selected
                  ? colors.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? colors.primary
                  : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
