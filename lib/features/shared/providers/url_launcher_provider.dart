import 'package:aqua/features/shared/shared.dart';
import 'package:url_launcher/url_launcher_string.dart';

final urlLauncherProvider =
    Provider.autoDispose<UrlLauncher>((_) => UrlLauncher());

class UrlLauncher {
  Future<void> open(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}
