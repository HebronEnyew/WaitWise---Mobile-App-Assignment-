class AdminModel {
  String id;
  String password;
  String service;

  AdminModel({required this.id, required this.password, required this.service});

  Map<String, dynamic> toMap() {
    return {'id': id, 'password': password, 'service': service};
  }

  factory AdminModel.fromMap(Map<String, dynamic> m) {
    return AdminModel(
      id: m['id'] as String? ?? '',
      password: m['password'] as String? ?? '',
      service: m['service'] as String? ?? '',
    );
  }
}
