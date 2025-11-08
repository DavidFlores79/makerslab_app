import 'dart:convert';

import '../../data/models/main_menu_item_model.dart';

class RemoteMainMenuResponse {
  int? page;
  int? pageSize;
  int? totalItems;
  List<MainMenuItemModel>? data;

  RemoteMainMenuResponse({
    this.page,
    this.pageSize,
    this.totalItems,
    this.data,
  });

  factory RemoteMainMenuResponse.fromRawJson(String str) =>
      RemoteMainMenuResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RemoteMainMenuResponse.fromJson(Map<String, dynamic> json) =>
      RemoteMainMenuResponse(
        page: json["page"],
        pageSize: json["pageSize"],
        totalItems: json["totalItems"],
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
    "page": page,
    "pageSize": pageSize,
    "totalItems": totalItems,
    "data": data,
  };
}
