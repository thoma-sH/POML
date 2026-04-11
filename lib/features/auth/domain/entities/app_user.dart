class AppUser {
  final String userId;
  final String email;
  final String name;

  AppUser({
    required this.userId,
    required this.email,
    required this.name,
  });

  // convert app user to json
  Map<String, dynamic> toJson() {
    return{
      'userId': userId,
      'email': email,
      'name': name,
    };
  }

  // convert json to app user
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      userId: jsonUser['userId'],
      email: jsonUser['email'],
      name: jsonUser['name']
    );
  }
}