class Machine {
  final String vendor;
  final String name;
  final String imageURL;

  final int id;

  Machine({required this.id, required this.vendor, required this.name, required this.imageURL});

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'],
      vendor: json['vendor'],
      name: json['name'],
      imageURL: json['imageurl.String'],
    );
  }
}
