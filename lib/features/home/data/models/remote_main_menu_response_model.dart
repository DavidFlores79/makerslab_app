import 'dart:convert';

import '../../domain/entities/remote_main_menu.dart';
import 'main_menu_item_model.dart';

RemoteMainMenuResponseModel remoteMainMenuResponseFromJson(String str) =>
    RemoteMainMenuResponseModel.fromJson(json.decode(str));

String remoteMainMenuResponseToJson(RemoteMainMenuResponseModel data) =>
    json.encode(data.toJson());

class RemoteMainMenuResponseModel extends RemoteMainMenuResponse {
  RemoteMainMenuResponseModel({
    super.page,
    super.pageSize,
    super.totalItems,
    super.data,
  });

  factory RemoteMainMenuResponseModel.fromJson(Map<String, dynamic> json) =>
      RemoteMainMenuResponseModel(
        page: json["page"],
        pageSize: json["pageSize"],
        totalItems: json["totalItems"],
        data:
            json["data"] == null
                ? []
                : List<MainMenuItemModel>.from(
                  json["data"]!.map((x) => MainMenuItemModel.fromJson(x)),
                ),
      );

  Map<String, dynamic> toJson() => {
    "page": page,
    "pageSize": pageSize,
    "totalItems": totalItems,
    "data":
        data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}
