import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/core/router/app_router.dart';
import 'package:recicla_radar_sp/core/theme/dark_theme.dart';
import 'package:recicla_radar_sp/core/theme/high_contrast_theme.dart';
import 'package:recicla_radar_sp/core/theme/light_theme.dart';
import 'package:recicla_radar_sp/data/local/alert_seen_store.dart';
import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/mock/district_seeds.dart';
import 'package:recicla_radar_sp/data/osm/osm_boundary_repository.dart';
import 'package:recicla_radar_sp/data/repositories/auth_repository.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/data/repositories/engine_alert_repository.dart';
import 'package:recicla_radar_sp/data/repositories/local_inspection_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_auth_repository.dart';
import 'package:recicla_radar_sp/data/repositories/mock_repositories.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/bins_provider.dart';
import 'package:recicla_radar_sp/state/boundaries_provider.dart';
import 'package:recicla_radar_sp/state/districts_provider.dart';
import 'package:recicla_radar_sp/state/filters_provider.dart';
import 'package:recicla_radar_sp/state/inspections_provider.dart';
import 'package:recicla_radar_sp/state/overview_provider.dart';
import 'package:recicla_radar_sp/state/session_provider.dart';
import 'package:recicla_radar_sp/state/settings_provider.dart';

/// Raiz do app: injeta repositórios (mock) e estados globais.
///
/// Para trocar o mock por Firebase, basta passar outras implementações das
/// interfaces de `data/repositories` aqui; nenhuma tela precisa mudar.
class ReciclaRadarApp extends StatelessWidget {
  const ReciclaRadarApp({
    super.key,
    required this.prefs,
    this.authRepository,
    this.binRepository,
    this.districtRepository,
    this.alertRepository,
    this.alertSeenStore,
    this.inspectionRepository,
    this.overviewRepository,
    this.boundaryRepository,
  });

  final SharedPreferences prefs;
  final AuthRepository? authRepository;
  final BinRepository? binRepository;
  final DistrictRepository? districtRepository;
  final AlertRepository? alertRepository;
  final AlertSeenStore? alertSeenStore;
  final InspectionRepository? inspectionRepository;
  final OverviewRepository? overviewRepository;
  final BoundaryRepository? boundaryRepository;

  @override
  Widget build(BuildContext context) {
    final bins = binRepository ?? MockBinRepository();
    final inspections = inspectionRepository ?? LocalInspectionRepository(prefs);

    return MultiProvider(
      providers: [
        Provider<BinRepository>.value(value: bins),
        ChangeNotifierProvider(create: (_) => InspectionsProvider(inspections)..load()),
        ChangeNotifierProvider(
          create: (_) => BoundariesProvider(
            boundaryRepository ??
                OsmBoundaryRepository(districtIds: [for (final seed in districtSeeds) seed.$1]),
          )..load(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(authRepository ?? MockAuthRepository()),
        ),
        ChangeNotifierProvider(create: (_) => FiltersProvider()),
        ChangeNotifierProvider(create: (_) => BinsProvider(bins)..load()),
        ChangeNotifierProvider(
          create: (_) => DistrictsProvider(districtRepository ?? MockDistrictRepository())..load(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, AlertsProvider>(
          create: (context) => AlertsProvider(
            alertRepository ?? EngineAlertRepository(SharedPrefsAlertStatusStore(prefs), inspections),
            alertSeenStore ?? SharedPrefsAlertSeenStore(prefs),
            context.read<SettingsProvider>().fillThreshold,
          )..load(),
          update: (_, settings, alerts) => alerts!..applyThreshold(settings.fillThreshold),
        ),
        ChangeNotifierProxyProvider<FiltersProvider, OverviewProvider>(
          create: (_) => OverviewProvider(overviewRepository ?? MockOverviewRepository()),
          update: (_, filters, overview) => overview!..applyFilters(filters),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router = createAppRouter(context.read<SessionProvider>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      title: 'Recicla Radar SP',
      debugShowCheckedModeBanner: false,
      theme: settings.highContrast ? buildHighContrastLightTheme() : buildLightTheme(),
      darkTheme: settings.highContrast ? buildHighContrastDarkTheme() : buildDarkTheme(),
      // Quando o aparelho pede texto em alto contraste, o app acompanha.
      highContrastTheme: buildHighContrastLightTheme(),
      highContrastDarkTheme: buildHighContrastDarkTheme(),
      themeMode: settings.themeMode,
      routerConfig: _router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // Respeita a fonte do sistema e soma a escolha feita nas Configurações.
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * settings.textScale).clamp(0.8, 2.2);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
