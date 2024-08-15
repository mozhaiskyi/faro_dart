class User {
  String? id;
  String? email;
  String? username;
  Map<String, dynamic>? attributes;

  User({
    this.id,
    this.email,
    this.username,
    this.attributes,
  });

  User.fromJson(dynamic json) {
    id = json['id'];
    email = json['email'];
    username = json['username'];
    attributes = json['attributes'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['email'] = email;
    map['username'] = username;
    map['attributes'] = attributes;
    return map;
  }
}
