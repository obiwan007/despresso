class Coffee {
  final String name;
  final String roaster;
  final String imageURL;
  final int id;

  Coffee(this.id, this.name, this.roaster, {required this.imageURL});

  factory Coffee.fromJson(Map<String, dynamic> json) {
    return Coffee(
      json['id'],
      json['name'],
      json['roaster'],
      imageURL: json['imageurl.String'],
    );
  }
}
