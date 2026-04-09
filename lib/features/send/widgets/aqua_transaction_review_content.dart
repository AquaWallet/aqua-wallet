import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaTransactionReviewContent extends HookConsumerWidget {
  const AquaTransactionReviewContent({
    super.key,
    required this.args,
    this.onFeeError,
  });

  final SendAssetArguments args;
  final VoidCallback? onFeeError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(sendAssetTxnProvider(args)).value;
    final input = ref.watch(sendAssetInputStateProvider(args)).valueOrNull;
    final formatter = ref.read(formatProvider);

    if (input == null) {
      return const SizedBox.shrink();
    }
    final isNonSatsAsset = input.asset.isNonSatsAsset;

    final cryptoAmount = formatter.formatAssetAmount(
      asset: input.asset,
      amount: input.amount,
      displayUnitOverride:
          SupportedDisplayUnits.fromAssetInputUnit(input.cryptoUnit),
      removeTrailingZeros: isNonSatsAsset,
    );

    final fiatAmount = input.displayConversionAmount != null
        ? !input.isFiatAmountInput
            ? '-${input.displayConversionAmount!}'
            : '-${input.rate.currency.format.symbol}${input.amountFieldText!}'
        : input.isFiatAmountInput
            ? '-${input.rate.currency.format.symbol}${input.amountFieldText!}'
            : '';

    return Column(
      children: [
        //ANCHOR - Send Summary
        AquaTransactionSummary.send(
          assetId: input.asset.id,
          assetIconUrl: input.asset.logoUrl,
          assetTicker: input.asset.getDisplayTicker(
            SupportedDisplayUnits.fromAssetInputUnit(input.cryptoUnit),
          ),
          amountCrypto: input.isFiatAmountInput
              ? input.displayConversionAmount != null
                  ? '-${input.displayConversionAmount!}'
                  : fiatAmount
              : '-$cryptoAmount',
          amountFiat: fiatAmount,
          colors: context.aquaColors,
        ),
        const SizedBox(height: 16),
        //ANCHOR - Recipient & Note Card
        _RecipientAndNoteCard(args: args),
        const SizedBox(height: 16),
        // ANCHOR - Fee Selection Card
        if (transaction != null && args.asset.isUsdtLiquid) ...{
          LiquidFeeSelector(args: args, onFeeError: onFeeError),
        } else ...{
          transaction?.whenOrNull(
                created: (t) => switch (args.asset) {
                  _ when (args.asset.isBTC) =>
                    BitcoinFeeSelector(args: args, onFeeError: onFeeError),
                  _ when (args.asset.isLiquid) =>
                    LiquidFeeSelector(args: args, onFeeError: onFeeError),
                  _ => const SizedBox.shrink(),
                },
              ) ??
              const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _RecipientAndNoteCard extends HookConsumerWidget {
  const _RecipientAndNoteCard({
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sendAssetInputStateProvider(args);
    final input = ref.watch(provider).valueOrNull!;

    final address = input.addressFieldText!;
    final note = input.note;

    final onNoteTap = useCallback(() async {
      final text = await AquaBottomSheet.show(
        context,
        content: AddNoteForm(note: note),
        colors: context.aquaColors,
      );
      ref.read(provider.notifier).updateNote(text);
    }, [note]);

    return AquaCard.surface(
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          AquaListItem(
            title: context.loc.recipient,
            onTap: () => context.copyToClipboard(address),
            contentWidget: AquaColoredText(
              text: address,
              style: AquaAddressTypography.body2.copyWith(
                color: context.aquaColors.textSecondary,
              ),
              colorType: ColoredTextEnum.coloredIntegers,
            ),
            iconTrailing: AquaIcon.copy(
              size: 18,
              color: context.aquaColors.textSecondary,
            ),
          ),
          Divider(
            height: 4,
            thickness: 1,
            color: context.aquaColors.surfaceSecondary,
          ),
          //ANCHOR - Add Note
          NoteListItem(
            note: note,
            onTap: onNoteTap,
          ),
        ],
      ),
    );
  }
}
