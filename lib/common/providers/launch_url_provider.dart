import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

final launchUrlProvider = AsyncNotifierProvider<LaunchUrlNotifier, void>(() {
  return LaunchUrlNotifier();
});

class LaunchUrlNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> launchUrl(String url) async {
    final canLaunch = await canLaunchUrlString(url);
    if (canLaunch) {
      return launchUrlString(url);
    }
    return false;
  }
}
