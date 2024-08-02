import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class MarketplaceErrorView extends ConsumerWidget {
  const MarketplaceErrorView({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GenericErrorWidget(
        description: message,
        buttonTitle: context.loc.unknownErrorButton,
        buttonAction: () => ref.invalidate(availableRegionsProvider),
      ),
    );
  }
}
