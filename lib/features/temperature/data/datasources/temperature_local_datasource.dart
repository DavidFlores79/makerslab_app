import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/temperature_entity.dart';

abstract class TemperatureLocalDataSource {
  Future<void> cacheLastTemperature(Temperature t);
  Temperature? getLastTemperature();
}

class TemperatureLocalDataSourceImpl implements TemperatureLocalDataSource {
  final SharedPreferences prefs;
  static const _kTemp = 'last_temp';
  static const _kHum = 'last_hum';
  static const _kTs = 'last_ts';

  TemperatureLocalDataSourceImpl({required this.prefs});

  @override
  Future<void> cacheLastTemperature(Temperature t) async {
    try {
      await prefs.setDouble(_kTemp, t.celsius);
      await prefs.setDouble(_kHum, t.humidity);
      await prefs.setString(_kTs, t.timestamp.toIso8601String());
    } catch (e, st) {
      throw CacheException('Failed to cache temperature', st);
    }
  }

  @override
  Temperature? getLastTemperature() {
    try {
      final t = prefs.getDouble(_kTemp);
      final h = prefs.getDouble(_kHum);
      final s = prefs.getString(_kTs);
      if (t == null || h == null || s == null) return null;
      return Temperature(celsius: t, humidity: h, timestamp: DateTime.parse(s));
    } catch (e, st) {
      throw CacheException('Failed to read cached temperature', st);
    }
  }
}
