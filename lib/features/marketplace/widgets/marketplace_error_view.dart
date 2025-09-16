import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

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
        buttonTitle: context.loc.retry,
        buttonAction: () => ref.invalidate(availableRegionsProvider),
      ),
    );
  }
}
