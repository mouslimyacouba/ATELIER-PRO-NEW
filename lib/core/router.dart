import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/atelier_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/clients/client_detail_screen.dart';
import '../screens/clients/client_form_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/new_order_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/mesures/mesures_screen.dart';
import '../screens/mesures/fiche_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/app_settings_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/terms_screen.dart';
import '../screens/stock/stock_screen.dart';
import '../screens/stock/stock_form_screen.dart';
import '../screens/modeles/modeles_screen.dart';
import '../screens/modeles/modele_form_screen.dart';
import '../screens/debug/metier_debug_screen.dart';
import '../screens/historique/commandes_historique_screen.dart';
import '../screens/historique/paiements_historique_screen.dart';
import '../screens/calendrier/calendrier_screen.dart';
import '../screens/rapports/reports_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final atelierProvider = context.read<AtelierProvider>();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([auth, atelierProvider]),
    redirect: (context, state) {
      final loggedIn = auth.session != null;
      final loggingIn = state.matchedLocation == '/auth';
      final onboarding = state.matchedLocation == '/onboarding';
      final verifyingEmail = state.matchedLocation == '/verify-email';
      final legalPage = state.matchedLocation == '/conditions' ||
          state.matchedLocation == '/confidentialite';

      if (!loggedIn) return loggingIn || legalPage ? null : '/auth';

      if (!auth.emailVerified) {
        return verifyingEmail || legalPage ? null : '/verify-email';
      }
      if (loggingIn || verifyingEmail) return '/';

      if (loggedIn &&
          !atelierProvider.loading &&
          atelierProvider.atelier == null &&
          !onboarding &&
          !legalPage) {
        return '/onboarding';
      }
      if (loggedIn && atelierProvider.atelier != null && onboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: '/conditions',
          builder: (context, state) => const TermsScreen()),
      GoRoute(
          path: '/confidentialite',
          builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(
        path: '/clients/nouveau',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:clientId/modifier',
        builder: (context, state) => ClientFormScreen(
          clientId: state.pathParameters['clientId'],
        ),
      ),
      GoRoute(
        path: '/mesures/nouvelle',
        builder: (context, state) => FicheFormScreen(
          initialClientId: state.uri.queryParameters['clientId'],
        ),
      ),
      GoRoute(
        path: '/mesures/:ficheId',
        builder: (context, state) => FicheFormScreen(
          ficheId: state.pathParameters['ficheId'],
        ),
      ),
      GoRoute(
        path: '/parametres/preferences',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  if (kDebugMode)
                    GoRoute(
                      path: 'debug/metier',
                      builder: (context, state) => const MetierDebugScreen(),
                    ),
                  GoRoute(
                    path: 'stock',
                    builder: (context, state) => const StockScreen(),
                    routes: [
                      GoRoute(
                        path: 'nouveau',
                        builder: (context, state) => const StockFormScreen(),
                      ),
                      GoRoute(
                        path: ':itemId',
                        builder: (context, state) => StockFormScreen(
                          itemId: state.pathParameters['itemId'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'modeles',
                    builder: (context, state) => const ModelesScreen(),
                    routes: [
                      GoRoute(
                        path: 'nouveau',
                        builder: (context, state) => const ModeleFormScreen(),
                      ),
                      GoRoute(
                        path: ':modeleId',
                        builder: (context, state) => ModeleFormScreen(
                          modeleId: state.pathParameters['modeleId'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'historique/commandes',
                    builder: (context, state) =>
                        const CommandesHistoriqueScreen(),
                  ),
                  GoRoute(
                    path: 'historique/paiements',
                    builder: (context, state) =>
                        const PaiementsHistoriqueScreen(),
                  ),
                  GoRoute(
                    path: 'calendrier',
                    builder: (context, state) => const CalendrierScreen(),
                  ),
                  GoRoute(
                    path: 'rapports',
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                builder: (context, state) => const ClientsScreen(),
                routes: [
                  GoRoute(
                    path: ':clientId',
                    builder: (context, state) => ClientDetailScreen(
                      clientId: state.pathParameters['clientId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/commandes',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'nouvelle',
                    builder: (context, state) => NewOrderScreen(
                      initialClientId: state.uri.queryParameters['clientId'],
                    ),
                  ),
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mesures',
                builder: (context, state) => MesuresScreen(
                  initialClientId: state.uri.queryParameters['clientId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parametres',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'confidentialite',
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                  GoRoute(
                    path: 'cgu',
                    builder: (context, state) => const TermsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
