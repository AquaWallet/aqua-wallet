import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/transaction/transaction_item_text.dart';
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
    String? dcFundedAddress,
    this.isPending = false,
    this.isFailed = false,
    this.isAutoSwap = false,
    this.isTopUp = false,
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = dcFundedAddress,
        isRefund = false,
        _isRedeposit = false,
        _isInsufficientFunds = false,
        _isFee = false,
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
    this.isRefund = false,
    this.isAutoSwap = false,
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = null,
        isTopUp = false,
        _isRedeposit = false,
        _isInsufficientFunds = false,
        _isFee = false,
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
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = '$fromAssetTicker → $toAssetTicker',
        isTopUp = false,
        isRefund = false,
        _isRedeposit = false,
        _isInsufficientFunds = false,
        _isFee = false,
        _type = AquaTransactionType.swap,
        _icon = AquaTransactionIcon.swap(
          colors: colors,
          isFailed: isFailed,
        );

  AquaTransactionItem.redeposit({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = null,
        isFailed = false,
        isRefund = false,
        isPending = false,
        isAutoSwap = false,
        isTopUp = false,
        _isRedeposit = true,
        _isInsufficientFunds = false,
        _isFee = false,
        _type = AquaTransactionType.receive,
        _icon = AquaTransactionIcon.receive(
          colors: colors,
        );

  AquaTransactionItem.insufficientFunds({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = null,
        isRefund = false,
        isFailed = false,
        isPending = false,
        isAutoSwap = false,
        isTopUp = false,
        _isRedeposit = false,
        _isInsufficientFunds = true,
        _isFee = false,
        _type = AquaTransactionType.receive,
        _icon = AquaTransactionIcon.receive(
          colors: colors,
          isFailed: true,
        );

  AquaTransactionItem.fee({
    super.key,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    required String feeLabel,
    this.isPending = false,
    this.isFailed = false,
    this.isAutoSwap = false,
    this.iconAssetId,
    this.onTap,
    this.colors,
    required this.text,
  })  : _title = feeLabel,
        isRefund = false,
        isTopUp = false,
        _isRedeposit = false,
        _isInsufficientFunds = false,
        _isFee = true,
        _type = AquaTransactionType.send,
        _icon = AquaTransactionIcon.send(
          colors: colors,
          isFailed: isFailed,
        );

  final String? iconAssetId;
  final DateTime timestamp;
  final String amountCrypto;
  final String amountFiat;
  final bool isAutoSwap;
  final bool isPending;
  final bool isFailed;
  final bool isRefund;
  final bool isTopUp;
  final VoidCallback? onTap;
  final AquaColors? colors;
  final TransactionItemText text;
  final Widget _icon;
  final String? _title;
  final AquaTransactionType _type;
  final bool _isRedeposit;
  final bool _isInsufficientFunds;
  final bool _isFee;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      borderOnForeground: false,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
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
                          isRefund: isRefund,
                          isRedeposit: _isRedeposit,
                          isFee: _isFee,
                          isPending: isPending,
                          isFailed: isFailed,
                          isTopUp: isTopUp,
                          colors: colors,
                          text: text,
                        ),
                        const SizedBox(width: 8),
                        switch (iconAssetId) {
                          AssetIds.btc => AquaAssetIcon.bitcoin(size: 18),
                          _ when (AssetIds.lbtc.contains(iconAssetId)) =>
                            AquaAssetIcon.liquidBitcoin(size: 18),
                          AssetIds.lightning =>
                            AquaAssetIcon.lightningBtc(size: 18),
                          AssetIds.usdtEth =>
                            AquaAssetIcon.usdtEthereum(size: 18),
                          AssetIds.usdtTether =>
                            AquaAssetIcon.usdtTether(size: 18),
                          _ when (AssetIds.mexas.contains(iconAssetId)) =>
                            AquaAssetIcon.mexas(size: 18),
                          _ when (AssetIds.usdtliquid.contains(iconAssetId)) =>
                            AquaAssetIcon.liquidBitcoin(size: 18),
                          AssetIds.usdtTrx => AquaAssetIcon.tron(size: 18),
                          AssetIds.usdtBep => AquaAssetIcon.binance(size: 18),
                          AssetIds.usdtSol => AquaAssetIcon.solana(size: 18),
                          AssetIds.usdtPol => AquaAssetIcon.polygon(size: 18),
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
                            child: AquaLinearProgressIndicator(
                              colors: colors,
                              barDuration: const Duration(seconds: 2),
                              intervalDuration: const Duration(seconds: 0),
                            ),
                          )
                        : AquaText.body2Medium(
                            text: switch (null) {
                              _ when isPending => '',
                              _ when isFailed => text.failed,
                              _ when _isInsufficientFunds =>
                                text.insufficientFunds,
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
                    _InsufficientFundsButton(
                      colors: colors,
                      text: text,
                    )
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
    required this.text,
  });

  final AquaColors? colors;
  final TransactionItemText text;

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
        text: text.addFunds,
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
    required this.isRedeposit,
    required this.isPending,
    required this.isFailed,
    required this.colors,
    required this.isFee,
    required this.isTopUp,
    required this.text,
  });

  final String? title;
  final AquaTransactionType type;
  final bool isRefund;
  final bool isRedeposit;
  final bool isPending;
  final bool isFailed;
  final bool isFee;
  final bool isTopUp;
  final AquaColors? colors;
  final TransactionItemText text;

  @override
  Widget build(BuildContext context) {
    final split = title?.split('→');
    if (type == AquaTransactionType.swap && split != null && split.length > 1) {
      final from = split.first.trim();
      final to = split.last.trim();
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AquaText.body1SemiBold(
            text: from,
            color: colors?.textPrimary,
          ),
          AquaIcon.arrowForward(
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
            _ when isRedeposit => text.redeposited,
            _ when isRefund => text.refund,
            AquaTransactionType.send when (isPending && isTopUp) =>
              text.toppingUp,
            AquaTransactionType.send when (isPending && !isFailed) =>
              text.sending,
            AquaTransactionType.send => text.sent,
            AquaTransactionType.receive when (isPending && !isFailed) =>
              text.receiving,
            AquaTransactionType.receive => text.received,
            AquaTransactionType.swap when (isPending && !isFailed) =>
              text.swapping,
            AquaTransactionType.swap => text.swapped,
          },
      color: colors?.textPrimary,
    );
  }
}
