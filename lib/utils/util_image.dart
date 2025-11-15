// ABOUTME: This file contains utility methods for loading and displaying images in the app
// ABOUTME: Handles both local assets and network images with error handling and caching
// ignore_for_file:constant_identifier_names

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

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

  // In-memory cache for SVG network images
  static final Map<String, String> _svgCache = {};

  static Widget buildIcon(MainMenuItemModel m, {double size = 60}) {
    if (m.assetPath != null) {
      // Local assets - no error handling needed as they're bundled
      if (m.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(m.assetPath!, width: size, height: size);
      } else {
        return Image.asset(m.assetPath!, width: size, height: size);
      }
    } else if (m.imageUrl != null) {
      // Network images - need error handling and caching
      if (m.imageUrl!.toLowerCase().endsWith('.svg')) {
        return _buildNetworkSvg(m.imageUrl!, size);
      } else {
        return _buildNetworkImage(m.imageUrl!, size);
      }
    } else {
      // Fallback icon when no image source is provided
      return Icon(Icons.extension, size: size);
    }
  }

  /// Builds a network PNG/JPG image with caching and error handling
  static Widget _buildNetworkImage(String url, double size) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: size * 0.4,
            height: size * 0.4,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Icon(
        Icons.broken_image_outlined,
        size: size,
        color: Colors.grey,
      ),
      // Limit image size to reduce memory usage
      maxWidthDiskCache: 400,
      maxHeightDiskCache: 400,
    );
  }

  /// Builds a network SVG with manual caching and error handling
  static Widget _buildNetworkSvg(String url, double size) {
    // Check cache first
    if (_svgCache.containsKey(url)) {
      return SvgPicture.string(
        _svgCache[url]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    // Fetch SVG from network
    return FutureBuilder<String>(
      future: _fetchSvgString(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Icon(
            Icons.broken_image_outlined,
            size: size,
            color: Colors.grey,
          );
        }

        // Cache the SVG string
        _svgCache[url] = snapshot.data!;

        // Limit cache size to prevent memory issues
        if (_svgCache.length > 50) {
          final firstKey = _svgCache.keys.first;
          _svgCache.remove(firstKey);
        }

        return SvgPicture.string(
          snapshot.data!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      },
    );
  }

  /// Fetches SVG content as a string from network
  static Future<String> _fetchSvgString(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load SVG: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching SVG: $e');
    }
  }
}
