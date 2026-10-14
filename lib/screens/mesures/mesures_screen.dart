import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/fiche_templates.dart';
import '../../core/theme.dart';
import '../../models/fiche_mesure.dart';
import '../../models/fiche_template.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/fiches_mesures_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spinner.dart';

final _date = DateFormat('dd/MM/yyyy');

class MesuresScreen extends StatefulWidget {
  const MesuresScreen({super.key, this.initialClientId});

  final String? initialClientId;

  @override
  State<MesuresScreen> createState() => _MesuresScreenState();
}

class _MesuresScreenState extends State<MesuresScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final userId = context.read<AtelierProvider>().atelier?.userId;
    if (userId != null) {
      context.read<ClientsProvider>().load(userId);
      context.read<FichesMesuresProvider>().load(userId);
    }
  }

  FicheTemplate get _template {
    final type = context.read<AtelierProvider>().atelier?.typeAtelier;
    return ficheTemplates[type] ?? ficheTemplates.values.last;
  }

  String get _newFichePath {
    final clientId = widget.initialClientId;
    if (clientId == null) return '/mesures/nouvelle';
    return '/mesures/nouvelle?clientId=${Uri.encodeComponent(clientId)}';
  }

  Future<void> _openNewFiche() async {
    await context.push<bool>(_newFichePath);
  }

  Future<void> _openFiche(FicheMesure fiche) async {
    await context.push<bool>(
      '/mesures/${Uri.encodeComponent(fiche.id)}',
    );
  }

  Future<void> _confirmDelete(FicheMesure fiche) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AtelierProColors.rougeAlerte),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error =
        await context.read<FichesMesuresProvider>().deleteFiche(fiche.id);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final fichesProvider = context.watch<FichesMesuresProvider>();
    final clientsProvider = context.watch<ClientsProvider>();
    final template = _template;
    final visibleFiches = widget.initialClientId == null
        ? fichesProvider.fiches
        : fichesProvider.forClient(widget.initialClientId!);

    return Scaffold(
      appBar: AppBar(title: Text(template.nomFiche)),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = context.read<AtelierProvider>().atelier?.userId;
          if (userId != null) {
            await Future.wait([
              context.read<ClientsProvider>().load(userId, forceRefresh: true),
              context
                  .read<FichesMesuresProvider>()
                  .load(userId, forceRefresh: true),
            ]);
          }
        },
        child: fichesProvider.loading && visibleFiches.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 240, child: Center(child: AtelierSpinner())),
                ],
              )
            : fichesProvider.error != null && visibleFiches.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 240,
                        child: ErrorState(
                          message: fichesProvider.error!,
                          onRetry: () {
                            final userId =
                                context.read<AtelierProvider>().atelier?.userId;
                            if (userId != null) {
                              context
                                  .read<FichesMesuresProvider>()
                                  .load(userId, forceRefresh: true);
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : visibleFiches.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: 300,
                            child: EmptyState(
                              icon: Icons.description_outlined,
                              title:
                                  'Aucune fiche ${template.nomFiche.toLowerCase()}',
                              subtitle:
                                  'Ajoutez votre première fiche pour enregistrer les mesures.',
                              actionLabel: 'Nouvelle fiche',
                              onAction: _openNewFiche,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleFiches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final fiche = visibleFiches[index];
                          final client = clientsProvider.byId(fiche.clientId);
                          return Card(
                            child: ListTile(
                              onTap: () => _openFiche(fiche),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x1F442A22),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: AtelierProColors.terracotta,
                                  size: 20,
                                ),
                              ),
                              title: Text(fiche.titre),
                              subtitle: Text(
                                '${client?.nomComplet ?? 'Client'} · '
                                '${_date.format(fiche.updatedAt)}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _confirmDelete(fiche);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'info',
                                    enabled: false,
                                    child: Text(
                                      '${fiche.mesures.length} champs',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AtelierProColors.onSurfaceMuted,
                                      ),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Supprimer'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewFiche,
        child: const Icon(Icons.add),
      ),
    );
  }
}
