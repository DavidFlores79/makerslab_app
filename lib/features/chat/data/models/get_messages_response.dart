import 'dart:convert';

import 'message_model.dart';

GetMessagesResponse getMessagesResponseFromJson(String str) =>
    GetMessagesResponse.fromJson(json.decode(str));

String getMessagesResponseToJson(GetMessagesResponse data) =>
    json.encode(data.toJson());

class GetMessagesResponse {
  String? module;
  String? conversationId;
  List<MessageModel>? messages;

  GetMessagesResponse({this.module, this.conversationId, this.messages});

  factory GetMessagesResponse.fromJson(Map<String, dynamic> json) =>
      GetMessagesResponse(
        module: json["module"],
        conversationId: json["conversationId"],
        messages:
            json["messages"] == null
                ? []
                : List<MessageModel>.from(
                  json["messages"]!.map((x) => MessageModel.fromJson(x)),
                ),
      );

  Map<String, dynamic> toJson() => {
    "module": module,
    "conversationId": conversationId,
    "messages":
        messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
  };
}
