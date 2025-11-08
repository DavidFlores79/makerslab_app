import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/storage/secure_storage_keys.dart';
import '../models/user_model.dart';

abstract class AuthUserLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearUser();
}

class AuthUserLocalDataSourceImpl implements AuthUserLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthUserLocalDataSourceImpl({required this.secureStorage});

  static const _keyUser = SecureStorageKeys.user;

  @override
  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await secureStorage.write(key: _keyUser, value: jsonStr);
  }

  @override
  Future<UserModel?> getUser() async {
    final jsonStr = await secureStorage.read(key: _keyUser);
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr));
  }

  @override
  Future<void> clearUser() async {
    await secureStorage.delete(key: _keyUser);
  }
}
