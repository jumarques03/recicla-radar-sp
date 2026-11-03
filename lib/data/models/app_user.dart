enum UserRole {
  inspector('Fiscal'),
  manager('Gestor');

  const UserRole(this.label);
  final String label;
}

class AppUser {
  const AppUser({required this.name, required this.email, required this.role});

  final String name;
  final String email;
  final UserRole role;
}
