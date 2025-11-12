// ABOUTME: This file contains the CatalogsRemoteDataSource interface and implementation
// ABOUTME: It handles API calls for fetching catalog data like countries

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/country_model.dart';

abstract class CatalogsRemoteDataSource {
  Future<List<CountryModel>> getCountries({
    int? limit,
    int? offset,
    String? search,
  });
}

class CatalogsRemoteDataSourceImpl implements CatalogsRemoteDataSource {
  final Dio dio;

  CatalogsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CountryModel>> getCountries({
    int? limit,
    int? offset,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limite'] = limit;
    if (offset != null) queryParams['desde'] = offset;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    debugPrint('GET ${ApiConfig.countriesEndpoint} -> params: $queryParams');

    final response = await _safeGet(
      ApiConfig.countriesEndpoint,
      queryParameters: queryParams,
    );

    final data = _ensureMap(response.data);

    if (!data.containsKey('countries') || data['countries'] is! List) {
      throw ApiException('Invalid response format: missing countries array');
    }

    final countriesList = data['countries'] as List;
    return countriesList
        .map((json) => CountryModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
