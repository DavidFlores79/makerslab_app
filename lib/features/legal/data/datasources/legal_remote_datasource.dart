// ABOUTME: This file contains the LegalRemoteDataSource interface and implementation
// ABOUTME: It handles API calls for fetching legal documents (terms/privacy policy)

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/legal_document_model.dart';

abstract class LegalRemoteDataSource {
  Future<LegalDocumentModel> getLegalDocument({
    required String type,
    required String language,
  });
}

class LegalRemoteDataSourceImpl implements LegalRemoteDataSource {
  final Dio dio;

  LegalRemoteDataSourceImpl({required this.dio});

  @override
  Future<LegalDocumentModel> getLegalDocument({
    required String type,
    required String language,
  }) async {
    final queryParams = <String, dynamic>{'type': type, 'language': language};

    debugPrint(
      'GET ${ApiConfig.legalDocumentsEndpoint} -> params: $queryParams',
    );

    final response = await _safeGet(
      ApiConfig.legalDocumentsEndpoint,
      queryParameters: queryParams,
    );

    final data = _ensureMap(response.data);

    // Handle multiple response formats
    if (data.containsKey('data')) {
      final dataField = data['data'];
      
      // If data is an array, get the first element
      if (dataField is List && dataField.isNotEmpty) {
        return LegalDocumentModel.fromJson(dataField[0] as Map<String, dynamic>);
      }
      
      // If data is an object
      if (dataField is Map) {
        return LegalDocumentModel.fromJson(dataField as Map<String, dynamic>);
      }
      
      throw ApiException('No legal documents found for the specified criteria');
    } else if (data.containsKey('_id') || data.containsKey('id') || data.containsKey('type')) {
      // Response is the document directly: { "id": ..., "type": ..., ... }
      return LegalDocumentModel.fromJson(data);
    } else {
      throw ApiException('Invalid response format: expected legal document data');
    }
  }

  /// --- Helpers ---

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
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException('Connection timeout. Check your connection.');
    }

    if (e.type == DioExceptionType.cancel) {
      throw ApiException('Request cancelled.');
    }

    if (e.response != null) {
      final message = _extractMessageFromResponse(e.response!);
      throw ApiException(message, statusCode: e.response?.statusCode);
    }

    throw ApiException(e.message ?? 'Unknown network error');
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Unexpected response format');
  }
}

/// --- Error extractor ---
String _extractMessageFromResponse(Response response) {
  try {
    final d = response.data;
    if (d == null) return 'Empty server response';

    if (d is Map<String, dynamic>) {
      if (d.containsKey('message')) {
        return d['message']?.toString() ?? 'Unknown error';
      }
      if (d.containsKey('error')) {
        return d['error']?.toString() ?? 'Unknown error';
      }
      if (d.containsKey('detail')) {
        return d['detail']?.toString() ?? 'Unknown error';
      }
    }

    return d.toString();
  } catch (_) {
    return 'Error parsing error message';
  }
}
