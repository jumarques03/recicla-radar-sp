import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';

/// Atalhos para ligar as telas entre si (alerta, lixeira e distrito).
/// Todos usam `go`, que troca de aba mantendo o caminho coerente.
extension AppNavigation on BuildContext {
  void openBin(String binId) => goNamed(AppRoutes.bin, pathParameters: {'id': binId});

  void openAlert(String alertId) => goNamed(AppRoutes.alert, pathParameters: {'id': alertId});

  /// Mapa de lixeiras centrado em uma lixeira.
  void showBinOnMap(String binId) =>
      goNamed(AppRoutes.bins, queryParameters: {AppRoutes.binParam: binId});

  /// Lista das lixeiras de um distrito.
  void showDistrictBins(String districtId) => goNamed(
        AppRoutes.bins,
        queryParameters: {AppRoutes.districtParam: districtId, AppRoutes.modeParam: 'lista'},
      );

  /// Mapa de demanda com o painel do distrito aberto.
  void showDistrict(String districtId) =>
      goNamed(AppRoutes.demand, queryParameters: {AppRoutes.districtParam: districtId});

  void showDistrictAlerts(String districtId) =>
      goNamed(AppRoutes.alerts, queryParameters: {AppRoutes.districtParam: districtId});

  void showBinAlerts(String binId) =>
      goNamed(AppRoutes.alerts, queryParameters: {AppRoutes.binParam: binId});

  void showAllBins() => goNamed(AppRoutes.bins, queryParameters: {AppRoutes.modeParam: 'lista'});

  void showAllAlerts() => goNamed(AppRoutes.alerts);
}
