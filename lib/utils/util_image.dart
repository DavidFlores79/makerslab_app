// ignore_for_file:constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../features/home/data/models/main_menu_item_model.dart';

/// Util to manage all image assets in app
class UtilImage {
  // static const String PAISAMEX_LOGO = "assets/images/brand/paisamex_logo.png";
  static const String PAISAMEX_LOGO_WHITE = "assets/images/brand/logo-app.png";
  static const String LOGO_MAIN = "assets/images/brand/logo-app.png";
  // static const String PAISAMEX_SLOGAN = "assets/images/brand/slogan_logo.png";

  // static const String SPLASH_BACKGROUND =
  //     "assets/images/brand/mexican_family.png";
  static const String SIGN_IN_BACKGROUND_1 =
      "assets/images/brand/background-image-1.jpg";
  static const String SIGN_IN_BACKGROUND_2 =
      "assets/images/brand/background-image-2.jpg";
  static const String SIGN_IN_BACKGROUND_3 =
      "assets/images/brand/background-image-3.jpg";

  static const String NOTIFICATION_ICON =
      "assets/images/brand/notification.png";

  static Widget buildIcon(MainMenuItemModel m, {double size = 60}) {
    if (m.assetPath != null) {
      // si es svg
      if (m.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(m.assetPath!, width: size, height: size);
      } else {
        return Image.asset(m.assetPath!, width: size, height: size);
      }
    } else if (m.imageUrl != null) {
      if (m.imageUrl!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(m.imageUrl!, width: size, height: size);
      } else {
        return Image.network(m.imageUrl!, width: size, height: size);
      }
    } else {
      return const Icon(Icons.extension);
    }
  }
}
