class MessageModel {
  String? role;
  List<MessageContentModel>? content;
  String? createdAt;

  MessageModel({this.role, this.content, this.createdAt});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];

    List<MessageContentModel> contentList = [];

    if (raw == null) {
      contentList = [];
    } else if (raw is String) {
      // API devolvió un string: lo convertimos a un content tipo texto
      contentList = [MessageContentModel(type: 'input_text', text: raw)];
    } else if (raw is Map) {
      // Un solo objeto
      contentList = [
        MessageContentModel.fromJson(Map<String, dynamic>.from(raw)),
      ];
    } else if (raw is List) {
      contentList =
          raw
              .map(
                (x) =>
                    MessageContentModel.fromJson(Map<String, dynamic>.from(x)),
              )
              .toList();
    } else {
      // Caso inesperado: fallback a lista vacía
      contentList = [];
    }

    return MessageModel(
      role: json['role'],
      content: contentList,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    "role": role,
    "content":
        content == null
            ? []
            : List<dynamic>.from(content!.map((x) => x.toJson())),
    "createdAt": createdAt,
  };
}

class MessageContentModel {
  String? type;
  String? text;
  String? imageUrl;

  MessageContentModel({this.type, this.text, this.imageUrl});

  factory MessageContentModel.fromJson(Map<String, dynamic> json) =>
      MessageContentModel(
        type: json["type"],
        text: json["text"],
        // Acepta tanto snake_case como camelCase
        imageUrl: json["image_url"] ?? json["imageUrl"],
      );

  Map<String, dynamic> toJson() => {
    "type": type,
    "text": text,
    "image_url": imageUrl,
  };
}
