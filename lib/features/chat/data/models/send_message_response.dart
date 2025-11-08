import 'dart:convert';

SendMessageResponse sendMessageAiResponseFromJson(String str) =>
    SendMessageResponse.fromJson(json.decode(str));

String sendMessageAiResponseToJson(SendMessageResponse data) =>
    json.encode(data.toJson());

class SendMessageResponse {
  String? assistant;

  SendMessageResponse({this.assistant});

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      SendMessageResponse(assistant: json["assistant"]);

  Map<String, dynamic> toJson() => {"assistant": assistant};
}
