import 'package:aqua/logger.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final _logger = CustomLogger(FeatureFlag.jan3AuthToken);

extension JwtTokenX on String {
  DateTime? get expiresAt {
    try {
      return JwtDecoder.getExpirationDate(this);
    } catch (e) {
      _logger.error('[Jan3AuthTokenManager] Failed to get expiration date: $e');
      return null;
    }
  }

  Duration? get remaining {
    try {
      return JwtDecoder.getRemainingTime(this);
    } catch (e) {
      _logger
          .warning('[Jan3AuthTokenManager] Failed to get remaining time: $e');
      return null;
    }
  }

  bool get isExpiredOrAboutTo {
    try {
      return JwtDecoder.isExpired(this) ||
          (remaining != null && remaining! <= const Duration(hours: 1));
    } catch (e) {
      _logger.warning(
          '[Jan3AuthTokenManager] Failed to check if token is expired: $e');
      // Treat invalid tokens as expired to force refresh
      return true;
    }
  }
}
