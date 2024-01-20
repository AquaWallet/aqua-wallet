import 'package:aqua/features/shared/shared.dart';
import 'package:package_info_plus/package_info_plus.dart';

final versionProvider = FutureProvider.autoDispose<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version;
  final build = packageInfo.buildNumber;
  return '$version ($build)';
});
