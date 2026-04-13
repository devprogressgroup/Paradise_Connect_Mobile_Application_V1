class PersonModel {
  final String name;
  final String phone;
  final String image;

  PersonModel({required this.name,required this.phone,required this.image});

 
  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      name: json['name'],
      phone: json['phone'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'image': image,
    };
  }
}