import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/transaction/transaction_summary_text.dart';
import 'package:ui_components/ui_components.dart';

class AquaTransactionSummary extends HookWidget {
  AquaTransactionSummary.send({
    super.key,
    required this.assetId,
    required this.assetTicker,
    required this.amountCrypto,
    required this.amountFiat,
    this.assetIconUrl,
    this.isPending = false,
    this.isConfidential = false,
    this.isLightning = false,
    this.colors,
  }) : _icon = AquaTransactionIcon.send(
          colors: colors,
        );

  AquaTransactionSummary.receive({
    super.key,
    required this.assetId,
    required this.assetTicker,
    required this.amountCrypto,
    required this.amountFiat,
    this.assetIconUrl,
    this.isPending = false,
    this.isConfidential = false,
    this.isLightning = false,
    this.colors,
  }) : _icon = AquaTransactionIcon.receive(
          colors: colors,
        );

  final String assetId;
  final String? assetIconUrl;
  final String assetTicker;
  final String amountCrypto;
  final String amountFiat;
  final bool isPending;
  final bool isConfidential;
  final bool isLightning;
  final AquaColors? colors;
  final Widget _icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (assetIconUrl.isValidUrl) ...{
              AquaAssetIcon.fromUrl(
                url: assetIconUrl!,
                size: 40,
              ),
            } else if (isLightning) ...{
              AquaAssetIcon.lightningBtcComposite(
                size: 40,
              )
            } else ...{
              AquaAssetIcon.fromAssetId(
                assetId: assetId,
                size: 40,
              ),
            },
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AquaText.h5SemiBold(
                        text: amountCrypto,
                        color: colors?.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      AquaText.h5SemiBold(
                        text: assetTicker,
                        color: colors?.textTertiary,
                      ),
                    ],
                  ),
                  if (!isConfidential) ...[
                    const SizedBox(height: 4),
                    AquaText.body2Medium(
                      text: amountFiat.isNotEmpty ? amountFiat : ' ',
                      color: colors?.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _icon,
          ],
        ),
        const SizedBox(height: 24),
        if (isPending) ...{
          AquaLinearProgressIndicator(
            barDuration: const Duration(seconds: 1),
            colors: colors,
          ),
        } else ...{
          DashedDivider(
            color: colors?.surfaceBorderSecondary,
          )
        }
      ],
    );
  }
}

class AquaSwapTransactionSummary extends StatelessWidget {
  const AquaSwapTransactionSummary({
    super.key,
    required this.fromAssetId,
    required this.toAssetId,
    required this.fromAmountCrypto,
    required this.toAmountCrypto,
    required this.fromAssetTicker,
    required this.toAssetTicker,
    this.fromAssetIconUrl,
    this.toAssetIconUrl,
    this.isPending = false,
    required this.colors,
    required this.text,
  });

  final String fromAssetId;
  final String toAssetId;
  final String? fromAssetIconUrl;
  final String? toAssetIconUrl;
  final String fromAssetTicker;
  final String toAssetTicker;
  final String fromAmountCrypto;
  final String toAmountCrypto;
  final bool isPending;
  final AquaColors? colors;
  final TransactionSummaryText text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwapLineItem(
          label: text.from,
          assetId: fromAssetId,
          assetTicker: fromAssetTicker,
          amountCrypto: fromAmountCrypto,
          assetIconUrl: fromAssetIconUrl,
          colors: colors,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isPending
                    ? AquaLinearProgressIndicator(
                        height: 18,
                        barDuration: const Duration(seconds: 1),
                        colors: colors,
                      )
                    : DashedDivider(
                        height: 18,
                        color: colors?.surfaceBorderSecondary,
                      ),
              ),
              const SizedBox(width: 16),
              AquaIcon.arrowDown(
                size: 18,
                color: colors?.textTertiary,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _SwapLineItem(
          label: text.to,
          assetId: toAssetId,
          assetTicker: toAssetTicker,
          amountCrypto: toAmountCrypto,
          assetIconUrl: toAssetIconUrl,
          colors: colors,
        ),
      ],
    );
  }
}

class _SwapLineItem extends StatelessWidget {
  const _SwapLineItem({
    required this.label,
    required this.assetId,
    required this.amountCrypto,
    required this.assetTicker,
    required this.assetIconUrl,
    required this.colors,
  });

  final String label;
  final String amountCrypto;
  final String assetTicker;
  final String assetId;
  final String? assetIconUrl;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaText.caption1SemiBold(
                text: label,
                color: colors?.textSecondary,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AquaText.subtitleSemiBold(
                    text: amountCrypto,
                    color: colors?.textPrimary,
                  ),
                  const SizedBox(width: 4),
                  AquaText.subtitleSemiBold(
                    text: assetTicker,
                    color: colors?.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (assetIconUrl.isValidUrl) ...{
          AquaAssetIcon.fromUrl(
            url: assetIconUrl!,
            size: 32,
          ),
        } else ...{
          AquaAssetIcon.fromAssetId(
            assetId: assetId,
            size: 32,
          ),
        }
      ],
    );
  }
}
