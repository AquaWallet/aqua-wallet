import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:coin_cz/config/config.dart';

class LoggerScreen extends StatelessWidget {
  static const routeName = '/loggerTable';
  const LoggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: logger.internalLogger,
      appBarTitle: context.loc.settingsScreenItemLogs,
      theme: TalkerScreenTheme(
        cardColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colors.background,
        textColor: Theme.of(context).colors.onBackground,
      ),
    );
  }
}
