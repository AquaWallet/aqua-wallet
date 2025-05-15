import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

enum AquaTransactionType {
  send,
  receive,
  swap,
}

class AquaTransactionItem extends HookWidget {
  AquaTransactionItem.send({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.isPending = false,
    this.isFailed = false,
    this.isAutoSwap = false,
    this.assetId,
    this.onTap,
    this.colors,
  })  : _title = null,
        _isRefund = false,
        _isInsufficientFunds = false,
        _type = AquaTransactionType.send,
        _icon = AquaTransactionIcon.send(
          colors: colors,
          isFailed: isFailed,
        );

  AquaTransactionItem.receive({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.isPending = false,
    this.isFailed = false,
    this.isAutoSwap = false,
    this.assetId,
    this.onTap,
    this.colors,
  })  : _title = null,
        _isRefund = false,
        _isInsufficientFunds = false,
        _type = AquaTransactionType.receive,
        _icon = AquaTransactionIcon.receive(
          colors: colors,
          isFailed: isFailed,
        );

  AquaTransactionItem.swap({
    super.key,
    required String fromAssetTicker,
    required String toAssetTicker,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.isPending = false,
    this.isFailed = false,
    this.isAutoSwap = false,
    this.assetId,
    this.onTap,
    this.colors,
  })  : _title = '$fromAssetTicker → $toAssetTicker',
        _isRefund = false,
        _isInsufficientFunds = false,
        _type = AquaTransactionType.swap,
        _icon = AquaTransactionIcon.swap(
          colors: colors,
          isFailed: isFailed,
        );

  AquaTransactionItem.refund({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.assetId,
    this.onTap,
    this.colors,
  })  : _title = null,
        isFailed = false,
        isPending = false,
        isAutoSwap = false,
        _isRefund = true,
        _isInsufficientFunds = false,
        _type = AquaTransactionType.receive,
        _icon = AquaTransactionIcon.receive(
          colors: colors,
        );

  AquaTransactionItem.insufficientFunds({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.assetId,
    this.onTap,
    this.colors,
  })  : _title = null,
        isFailed = false,
        isPending = false,
        isAutoSwap = false,
        _isRefund = false,
        _isInsufficientFunds = true,
        _type = AquaTransactionType.receive,
        _icon = AquaTransactionIcon.receive(
          colors: colors,
          isFailed: true,
        );

  final String? assetId;
  final DateTime timestamp;
  final String amountCrypto;
  final String amountFiat;
  final bool isAutoSwap;
  final bool isPending;
  final bool isFailed;
  final VoidCallback? onTap;
  final AquaColors? colors;
  final Widget _icon;
  final String? _title;
  final AquaTransactionType _type;
  final bool _isRefund;
  final bool _isInsufficientFunds;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      borderOnForeground: false,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _icon,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TransactionTitle(
                          title: _title,
                          type: _type,
                          isRefund: _isRefund,
                          isPending: isPending,
                          isFailed: isFailed,
                          colors: colors,
                        ),
                        const SizedBox(width: 8),
                        switch (assetId) {
                          AssetIds.btc => AquaAssetIcon.bitcoin(size: 18),
                          _ when (AssetIds.lbtc.contains(assetId)) =>
                            AquaAssetIcon.liquidBitcoin(size: 18),
                          AssetIds.lightning =>
                            AquaAssetIcon.lightningBtc(size: 18),
                          AssetIds.usdtEth =>
                            AquaAssetIcon.usdtTether(size: 18),
                          _ when (AssetIds.usdtliquid.contains(assetId)) =>
                            AquaAssetIcon.liquidBitcoin(size: 18),
                          AssetIds.usdtTrx => AquaAssetIcon.tron(size: 18),
                          AssetIds.usdtBep => AquaAssetIcon.binance(size: 18),
                          AssetIds.usdtSol => AquaAssetIcon.solana(size: 18),
                          AssetIds.usdtTon => AquaAssetIcon.ton(size: 18),
                          AssetIds.layer2 => AquaAssetIcon.l2Bitcoin(size: 18),
                          _ => const SizedBox.shrink(),
                        },
                      ],
                    ),
                    const SizedBox(height: 4),
                    isPending
                        ? SizedBox(
                            width: 72,
                            child: AquaLinearProgressIndicator(colors: colors),
                          )
                        : AquaText.body2Medium(
                            text: switch (null) {
                              _ when isPending => '',
                              _ when isFailed => context.loc.failed,
                              _ when _isInsufficientFunds =>
                                context.loc.insufficientFunds,
                              _ => timestamp.format()
                            },
                            color: isFailed || _isInsufficientFunds
                                ? colors?.accentDanger
                                : colors?.textSecondary,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isInsufficientFunds) ...{
                    _InsufficientFundsButton(colors: colors)
                  } else ...{
                    AquaText.body1SemiBold(
                      text: amountCrypto,
                      color: colors?.textPrimary,
                    )
                  },
                  if (!_isInsufficientFunds) ...[
                    const SizedBox(height: 4),
                    AquaText.body2Medium(
                      text: amountFiat,
                      color: colors?.textSecondary,
                    ),
                  ],
                ],
              ),
            ],
            // style: AquaTypography.body1,
          ),
        ),
      ),
    );
  }
}

class _InsufficientFundsButton extends StatelessWidget {
  const _InsufficientFundsButton({
    required this.colors,
  });

  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors?.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AquaText.body2SemiBold(
        text: context.loc.addFunds,
        color: colors?.textPrimary,
      ),
    );
  }
}

class _TransactionTitle extends StatelessWidget {
  const _TransactionTitle({
    required this.title,
    required this.type,
    required this.isRefund,
    required this.isPending,
    required this.isFailed,
    required this.colors,
  });

  final String? title;
  final AquaTransactionType type;
  final bool isRefund;
  final bool isPending;
  final bool isFailed;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    final split = title?.split('→');
    if (type == AquaTransactionType.swap && split != null && split.length > 1) {
      final from = split.first;
      final to = split.last;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AquaText.body1SemiBold(
            text: from,
            color: colors?.textPrimary,
          ),
          AquaIcon.arrowRight(
            size: 16,
            color: colors?.textSecondary,
          ),
          AquaText.body1SemiBold(
            text: to,
            color: colors?.textPrimary,
          ),
        ],
      );
    }
    return AquaText.body1SemiBold(
      text: title ??
          switch (type) {
            _ when isRefund => context.loc.refund,
            AquaTransactionType.send when (isPending || isFailed) =>
              context.loc.sending,
            AquaTransactionType.send => context.loc.sent,
            AquaTransactionType.receive when (isPending || isFailed) =>
              context.loc.receiving,
            AquaTransactionType.receive => context.loc.received,
            AquaTransactionType.swap when (isPending || isFailed) =>
              context.loc.swapping,
            AquaTransactionType.swap => context.loc.swapped,
          },
      color: colors?.textPrimary,
    );
  }
}
