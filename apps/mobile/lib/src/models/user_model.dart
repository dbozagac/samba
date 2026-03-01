class UserModel {
  final int id;
  final String username;
  final String tcNo;
  final String email;
  final String phone;

  const UserModel({
    required this.id,
    required this.username,
    required this.tcNo,
    required this.email,
    required this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      tcNo: json['tcNo'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }
}
