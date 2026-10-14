import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/clients_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spinner.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final userId = context.read<AtelierProvider>().atelier?.userId;
      if (userId != null) context.read<ClientsProvider>().load(userId);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openNewClient() async {
    await context.push<bool>('/clients/nouveau');
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = context.watch<ClientsProvider>();
    final filtered = _query.isEmpty
        ? clientsProvider.clients
        : clientsProvider.clients
            .where((c) => c.nomComplet.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un client…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final userId = context.read<AtelierProvider>().atelier?.userId;
                if (userId != null) {
                  await context
                      .read<ClientsProvider>()
                      .load(userId, forceRefresh: true);
                }
              },
              child: clientsProvider.loading && clientsProvider.clients.isEmpty
                  ? const AtelierSpinner()
                  : clientsProvider.error != null && clientsProvider.clients.isEmpty
                      ? ErrorState(
                          message: clientsProvider.error!,
                          onRetry: () {
                            final userId = context.read<AtelierProvider>().atelier?.userId;
                            if (userId != null) {
                              context
                                  .read<ClientsProvider>()
                                  .load(userId, forceRefresh: true);
                            }
                          },
                        )
                      : filtered.isEmpty
                          ? _query.isNotEmpty
                              ? EmptyState(
                                  icon: Icons.search_off,
                                  title: 'Aucun résultat',
                                  subtitle: 'Aucun client ne correspond à "$_query".',
                                )
                              : EmptyState(
                                  icon: Icons.people_outline,
                                  title: 'Aucun client',
                                  subtitle: 'Ajoutez votre premier client pour commencer.',
                                  actionLabel: 'Ajouter un client',
                                  onAction: _openNewClient,
                                )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final client = filtered[i];
                                return Card(
                                  child: ListTile(
                                    onTap: () => context.push('/clients/${client.id}'),
                                    leading: CircleAvatar(
                                      backgroundColor: AtelierProColors.terracotta.withValues(alpha: 0.12),
                                      backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                                      child: client.photoUrl == null
                                          ? Text(
                                              client.nomComplet.isNotEmpty ? client.nomComplet[0].toUpperCase() : '?',
                                              style: const TextStyle(color: AtelierProColors.terracotta),
                                            )
                                          : null,
                                    ),
                                    title: Text(client.nomComplet),
                                    subtitle: Text(client.telephone ?? 'Pas de téléphone'),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewClient,
        child: const Icon(Icons.add),
      ),
    );
  }
}
