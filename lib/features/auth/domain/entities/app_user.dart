class AppUser {
  final String userId;
  final String username;

  AppUser({
    required this.userId,
    required this.username,
  });
  // Marshalled from the original AppUser class, this entity represents a user in the app's domain layer.
  // The toJson method converts the AppUser instance into a JSON-compatible map,
  //  which can be useful for serialization 
  // (e.g., when storing user data in a database or sending it over a network). 
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
    };
  }

  // Unmarshalled from the original AppUser class, this entity represents a user in the app's domain layer.
  // The toJson method converts the AppUser instance into a JSON-compatible map,
  // The fromJson factory constructor creates an AppUser instance from a JSON map, allowing 
  // for easy deserialization of user data.
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      userId: jsonUser['userId'],
      username: jsonUser['username'],
    );
  }
}