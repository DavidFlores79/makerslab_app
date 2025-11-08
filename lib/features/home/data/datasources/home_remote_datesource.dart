import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/main_menu_item_model.dart';
import '../models/remote_main_menu_response_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<MainMenuItemModel>> getRemoteMenuItems();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MainMenuItemModel>> getRemoteMenuItems() async {
    debugPrint('GET ${ApiConfig.mainMenuEndpoint}');
    final response = await _safeGet(ApiConfig.mainMenuEndpoint);

    return RemoteMainMenuResponseModel.fromJson(
          _ensureMap(response.data),
        ).data ??
        [];
  }

  /// --- Helpers ---

  /// Safe GET with error handling
  Future<Response> _safeGet(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response;
      }

      final message = _extractMessageFromResponse(response);
      throw ApiException(message, statusCode: response.statusCode);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow; // nunca llega aquí, pero por typing
    }
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión.');
    }

    if (e.type == DioExceptionType.cancel) {
      throw ApiException('Solicitud cancelada por el usuario.');
    }

    if (e.response != null) {
      final message = _extractMessageFromResponse(e.response!);
      throw ApiException(message, statusCode: e.response?.statusCode);
    }

    throw ApiException(e.message ?? 'Error de red desconocido');
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Formato de respuesta inesperado');
  }
}

/// --- Error extractor ---
String _extractMessageFromResponse(Response response) {
  try {
    final d = response.data;
    if (d == null) return 'Respuesta vacía del servidor';

    if (d is Map<String, dynamic>) {
      if (d.containsKey('message')) {
        return d['message']?.toString() ?? 'Error desconocido';
      }
      if (d.containsKey('error')) {
        return d['error']?.toString() ?? 'Error desconocido';
      }
      if (d.containsKey('detail')) {
        return d['detail']?.toString() ?? 'Error desconocido';
      }

      if (d.containsKey('errors') && d['errors'] is Iterable) {
        final errors = List.from(d['errors'] as Iterable);
        final msgs =
            errors
                .map((e) {
                  if (e is Map && (e['msg'] != null || e['message'] != null)) {
                    return (e['msg'] ?? e['message']).toString();
                  }
                  return e.toString();
                })
                .where((s) => s.isNotEmpty)
                .toList();

        if (msgs.isNotEmpty) {
          return msgs.length == 1 ? msgs.first : msgs.take(3).join(' • ');
        }
      }

      return d.keys.take(3).map((k) => '$k:${d[k]}').join(', ');
    }

    return d.toString();
  } catch (_) {
    return 'Error al parsear el mensaje de error';
  }
}
