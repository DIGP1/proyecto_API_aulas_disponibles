class user_login {
  final String email;
  final String password;

  user_login({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
