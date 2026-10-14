import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/client_finance.dart';
import '../../core/contact_actions.dart';
import '../../core/currency_formatter.dart';
import '../../core/storage_service.dart';
import '../../core/theme.dart';
import '../../models/client.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../providers/atelier_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/fiches_mesures_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spinner.dart';
import 'widgets/client_finance_card.dart';
import 'widgets/client_measure_section.dart';

final _money = CurrencyFormatter.formatter;
final _dateShort = DateFormat('dd/MM/yyyy');

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  bool _initialized = false;
  bool _uploadingPhoto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final userId = context.read<AtelierProvider>().atelier?.userId;
      if (userId != null) {
        context.read<ClientsProvider>().load(userId);
        context.read<OrdersProvider>().load(userId);
        context.read<FichesMesuresProvider>().load(userId);
      }
    }
  }

  Future<void> _editClient(AtelierClient client) async {
    await context.push<bool>(
      '/clients/${Uri.encodeComponent(client.id)}/modifier',
    );
  }

  Future<void> _retryClientData(String userId) async {
    await Future.wait([
      context.read<ClientsProvider>().load(userId, forceRefresh: true),
      context.read<OrdersProvider>().load(userId, forceRefresh: true),
      context.read<FichesMesuresProvider>().load(userId, forceRefresh: true),
    ]);
  }

  Future<void> _changePhoto() async {
    final file = await StorageService.pickImage();
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final userId = context.read<AtelierProvider>().atelier?.userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atelier introuvable. Réessaie après reconnexion.')),
        );
        return;
      }
      final url = await StorageService.upload(
        bucket: 'photos',
        userId: userId,
        key: widget.clientId,
        file: file,
      );
      if (!mounted) return;
      final error = await context.read<ClientsProvider>().updatePhoto(widget.clientId, url);
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'envoi : $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String clientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: Text(
          '$clientName et ses fiches de mesures seront supprimés si aucun '
          'historique de commande ou de paiement ne lui est associé. Les '
          'commandes et paiements ne seront jamais supprimés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AtelierProColors.rougeAlerte)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final userId = context.read<AtelierProvider>().atelier?.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atelier introuvable. Réessaie après reconnexion.'),
        ),
      );
      return;
    }
    final error =
        await context.read<ClientsProvider>().deleteClient(widget.clientId, userId);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/clients');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = context.watch<ClientsProvider>();
    final client = clientsProvider.byId(widget.clientId);
    final ordersProvider = context.watch<OrdersProvider>();
    final fichesProvider = context.watch<FichesMesuresProvider>();

    if (client == null) {
      if (clientsProvider.loading) {
        return const Scaffold(body: AtelierSpinner());
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Client introuvable')),
        body: ErrorState(
          message: clientsProvider.error ??
              'Ce client est introuvable ou n’est plus accessible.',
          onRetry: () {
            final userId = context.read<AtelierProvider>().atelier?.userId;
            if (userId != null) _retryClientData(userId);
          },
        ),
      );
    }

    final orders = ordersProvider.orders
        .where((order) =>
            order.userId == client.userId && order.clientId == client.id)
        .toList();
    final payments = ordersProvider.payments
        .where((payment) =>
            payment.userId == client.userId && payment.clientId == client.id)
        .toList();
    final clientFiches = fichesProvider.forClient(client.id);
    final finance = ClientFinanceSummary.fromOrders(orders);

    return Scaffold(
      appBar: AppBar(
        title: Text(client.nomComplet),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/clients');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier le client',
            onPressed: () => _editClient(client),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer le client',
            onPressed: () => _confirmDelete(context, client.nomComplet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _changePhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AtelierProColors.terracotta.withValues(alpha: 0.12),
                    backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                    child: _uploadingPhoto
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : (client.photoUrl == null
                            ? Text(
                                client.nomComplet.isNotEmpty ? client.nomComplet[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 28, color: AtelierProColors.terracotta),
                              )
                            : null),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: AtelierProColors.terracotta, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.phone, label: client.telephone ?? 'Non renseigné'),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.location_on_outlined, label: client.adresse ?? 'Non renseignée'),
                  if (client.notes != null && client.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.notes, label: client.notes!),
                  ],
                  if (client.telephone != null && client.telephone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => callPhone(client.telephone!),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Appeler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openWhatsApp(
                              client.telephone!,
                              message: 'Bonjour ${client.nomComplet}, ',
                            ),
                            icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (ordersProvider.loading && orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Chargement des commandes…'),
                  ],
                ),
              ),
            )
          else if (ordersProvider.error != null && orders.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(ordersProvider.error!),
                trailing: IconButton(
                  tooltip: 'Réessayer',
                  onPressed: () => _retryClientData(client.userId),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            )
          else
            ClientFinanceCard(summary: finance),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Commandes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => context.push('/commandes/nouvelle?clientId=${client.id}'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle'),
              ),
            ],
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aucune commande pour ce client')),
            )
          else
            for (final order in orders)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => context.push('/commandes/${order.id}'),
                  title: Text(order.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${_money.format(order.prixTotal)} · reste ${_money.format(order.remaining)}'),
                  trailing: StatusPill(label: order.status.label, color: order.status.color),
                ),
              ),
          const SizedBox(height: 12),
          ClientMeasureSection(
              fiches: clientFiches,
              loading: fichesProvider.loading,
              error: fichesProvider.error,
              onRetry: () =>
                  fichesProvider.load(client.userId, forceRefresh: true),
              onAdd: () => context.push(
                '/mesures/nouvelle?clientId=${Uri.encodeComponent(client.id)}',
              ),
              onOpenAll: () => context.push(
                '/mesures?clientId=${Uri.encodeComponent(client.id)}',
              ),
              onOpenFiche: (fiche) =>
                  context.push('/mesures/${Uri.encodeComponent(fiche.id)}'),
          ),
          const SizedBox(height: 20),
          const Text('Historique', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _ClientTimeline(orders: orders, payments: payments),
        ],
      ),
    );
  }
}

/// Fusionne commandes (création) et paiements (encaissements) en une seule
/// liste chronologique — Firestore ne permettant pas de requête combinée
/// entre deux collections, la fusion se fait côté client sur des listes déjà
/// chargées en mémoire (peu volumineuses par client, coût négligeable).
class _ClientTimeline extends StatelessWidget {
  final List<AtelierOrder> orders;
  final List<AtelierPayment> payments;
  const _ClientTimeline({required this.orders, required this.payments});

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.read<OrdersProvider>();
    final events = <_TimelineEvent>[
      for (final o in orders) ...[
        _TimelineEvent(
          date: o.createdAt,
          icon: Icons.add_box_outlined,
          color: AtelierProColors.tertiary,
          title: 'Commande créée ${o.numeroFormate.isNotEmpty ? "(${o.numeroFormate})" : ""}',
          subtitle: o.description,
          trailing: _money.format(o.prixTotal),
        ),
        for (final h in ordersProvider.historiqueForOrder(o.id))
          _TimelineEvent(
            date: h.createdAt,
            icon: Icons.edit_note_outlined,
            color: AtelierProColors.secondary,
            title: 'Modification (${h.champModifie})',
            subtitle: '${h.ancienneValeur ?? '—'} ➔ ${h.nouvelleValeur ?? '—'}',
            trailing: o.numeroFormate.isNotEmpty ? o.numeroFormate : null,
          ),
      ],
      for (final p in payments)
        _TimelineEvent(
          date: p.datePaiement,
          icon: Icons.payments_outlined,
          color: AtelierProColors.statusDone,
          title: 'Paiement reçu',
          subtitle: p.modeLabel,
          trailing: _money.format(p.montant),
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aucune activité pour le moment')),
      );
    }

    return Column(
      children: [
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.icon, size: 16, color: event.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (event.trailing != null)
                            Text(event.trailing!,
                                style: AtelierProTheme.dataStyle(fontSize: 13, color: event.color)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AtelierProColors.onSurfaceVariant),
                      ),
                      Text(_dateShort.format(event.date), style: const TextStyle(fontSize: 11, color: AtelierProColors.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineEvent {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;

  _TimelineEvent({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AtelierProColors.terracotta),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }
}
