/// Nomes e caminhos das rotas do app.
abstract final class AppRoutes {
  static const String login = 'login';
  static const String register = 'cadastro';
  static const String forgotPassword = 'recuperar-senha';
  static const String home = 'home';
  static const String demand = 'demanda';
  static const String bins = 'lixeiras';
  static const String bin = 'lixeira';
  static const String alerts = 'alertas';
  static const String alert = 'alerta';
  static const String inspection = 'vistoria';
  static const String settings = 'configuracoes';

  // Nomes dos filtros que as rotas aceitam na URL (ex.: /lixeiras?distrito=123&modo=lista).
  static const String districtParam = 'distrito';
  static const String binParam = 'lixeira';
  static const String modeParam = 'modo';

  static const String loginPath = '/login';
  static const String registerPath = '/cadastro';
  static const String forgotPasswordPath = '/recuperar-senha';
  static const String homePath = '/home';

  static const Set<String> publicPaths = {loginPath, registerPath, forgotPasswordPath};
}
