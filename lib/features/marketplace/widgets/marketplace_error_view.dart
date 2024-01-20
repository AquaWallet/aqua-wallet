import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

class MarketplaceErrorView extends ConsumerWidget {
  const MarketplaceErrorView({
    Key? key,
    this.message,
  }) : super(key: key);

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GenericErrorWidget(
        description: message,
        buttonTitle: AppLocalizations.of(context)!.unknownErrorButton,
        buttonAction: () => ref.invalidate(availableRegionsProvider),
      ),
    );
  }
}
