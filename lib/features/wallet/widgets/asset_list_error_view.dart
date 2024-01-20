import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

class AssetListErrorView extends ConsumerWidget {
  const AssetListErrorView({
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
        buttonAction: () {
          ref.invalidate(availableAssetsProvider);
          ref.invalidate(reloadNotifier);
        },
      ),
    );
  }
}
