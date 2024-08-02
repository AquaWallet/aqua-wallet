import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

/// Navigates to the SendAssetContainerScreen with the given arguments
final sendNavigationEntryProvider = Provider.autoDispose
    .family<void Function(BuildContext), SendAssetArguments>((ref, arguments) {
  // If no new values in args, use existing providers values
  final asset = arguments.asset;
  final address = arguments.input ?? ref.read(sendAddressProvider);
  final amount =
      arguments.userEnteredAmount ?? ref.read(userEnteredAmountProvider);
  final lnurlParseResult =
      arguments.lnurlParseResult ?? ref.read(lnurlParseResultProvider);

  final startScreen =
      SendAssetStartScreenExtension.determineStartScreen(address, amount);
  logger.d(
      "[Send][Navigation] send container screen - initial provider asset: $asset - address: ${ref.read(sendAddressProvider)} - amount: ${ref.read(userEnteredAmountProvider)} - startScreen: $startScreen");

  final newArguments = arguments.copyWith(
    asset: asset,
    input: address,
    userEnteredAmount: amount,
    startScreen: startScreen,
    lnurlParseResult: lnurlParseResult,
  );

  return (BuildContext context) {
    Navigator.of(context).pushNamed(
      SendAssetContainerScreen.routeName,
      arguments: newArguments,
    );
  };
});

/// Navigates to a specific screen in the Send flow conditionally

/// Navigates directly to the SendAssetAmountScreen
final sendNavigationAmountScreenProvider =
    Provider.autoDispose<void Function(BuildContext)>((ref) {
  return (BuildContext context) {
    Navigator.of(context).pushNamed(
      SendAssetAmountScreen.routeName,
      arguments: null,
    );
  };
});
