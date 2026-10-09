import 'package:flutter/material.dart';

import '../../core/theme.dart';

Future<bool?> showDeleteAccountConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer mon compte ?'),
      content: const Text(
        'Ton atelier et toutes tes données seront définitivement supprimés, '
        'puis ton compte de connexion sera supprimé. Cette action est '
        'irréversible.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Supprimer',
            style: TextStyle(color: AtelierProColors.rougeAlerte),
          ),
        ),
      ],
    ),
  );
}

Future<String?> showDeleteAccountPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirme ton identité'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> showReloginBeforeDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reconnexion nécessaire'),
      content: const Text(
        'Pour supprimer ce compte en toute sécurité, déconnecte-toi puis '
        'reconnecte-toi avec le même fournisseur. Reviens ensuite dans les '
        'paramètres pour relancer la suppression.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
}
