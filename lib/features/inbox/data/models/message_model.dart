class MessageModel {
  final String name;
  final String message;
  final String time;
  final String image;

  MessageModel({required this.name,required this.message,required this.time,required this.image});

 
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      name: json['name'],
      message: json['message'],
      time: json['time'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'message': message,
      'time': time,
      'image': image,
    };
  }
}