import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/basic_transaction_side_sheet.dart';
import 'package:aqua/features/desktop/widgets/lightning_transaction_side_sheet.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/settings/manage_assets/models/models.dart'
    as assets;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_item_localizations_extension.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

final tempDate = DateTime(2025, 1, 1);

final customFeeInputScreenArguments = CustomFeeInputScreenArguments(
  sendArgs: SendAssetArguments.fromAsset(assets.Asset.btc()),
  minFeeRateOption: BitcoinFeeModelMin(
    feeRate: 5,
    feeSats: 12,
    feeFiat: 5,
  ),
);

final getMockSavingsAccounts = [
  AssetUiModel(
    assetId: AssetIds.btc,
    name: 'Bitcoin',
    subtitle: 'BTC',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ),
];

final getMockSpendingAccounts = [
  AssetUiModel(
    assetId: AssetIds.layer2,
    name: 'L2 Bitcoin',
    subtitle: 'L-BTC',
    amount: '0.00489438',
    amountFiat: '\$4,379.68',
  ),
  AssetUiModel(
    assetId: AssetIds.usdtliquid.first,
    name: 'Tether USDt',
    subtitle: 'USDt',
    amount: '11,020.00',
    amountFiat: '',
  ),
];

const getMockDataSwapOrder = [
  SwapOrderUiModel(
    title: 'bArmJxFZh9PK',
    subtitle: 'Timeout: 322199',
    subtitleTrailing: 'Invoice Set',
    titleTrailing: '33,000',
  ),
  SwapOrderUiModel(
    title: 'bArmJxFZh9PK',
    subtitle: 'Timeout: 322199',
    subtitleTrailing: 'Invoice Set',
    titleTrailing: '33,000',
  ),
  SwapOrderUiModel(
    title: 'bArmJxFZh9PK',
    subtitle: 'Timeout: 322199',
    subtitleTrailing: 'Invoice Set',
    titleTrailing: '33,000',
  ),
  SwapOrderUiModel(
    title: 'bArmJxFZh9PK',
    subtitle: 'Timeout: 322199',
    subtitleTrailing: 'Invoice Set',
    titleTrailing: '33,000',
  ),
  SwapOrderUiModel(
    title: 'bArmJxFZh9PK',
    subtitle: 'Timeout: 322199',
    subtitleTrailing: 'Invoice Set',
    titleTrailing: '33,000',
  ),
];

List<Widget> getMockTransactionsPending(BuildContext context) => [
      AquaTransactionItem.send(
        isPending: true,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        text: context.loc.transactionItemLocalizations,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.send(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: true,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: true,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        iconAssetId: AssetIds.lightning,
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: LightningTransactionSideSheet.send(
            iconAssetId: AssetIds.lightning,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: true,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: true,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.receive(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '0.04738384',
            amountFiat: '\$4,558.51',
            colors: context.aquaColors,
            isPending: true,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        isPending: true,
        isFailed: false,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        colors: context.aquaColors,
        timestamp: tempDate,
        text: context.loc.transactionItemLocalizations,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '0.04738384',
            amountFiat: '\$4,558.51',
            colors: context.aquaColors,
            isPending: true,
            isFailed: false,
          ),
        ),
      ),
    ];

List<Widget> getMockTransactions(BuildContext context) => [
      AquaListItem(
          colors: context.aquaColors,
          title: 'Chip Sweep',
          titleColor: context.aquaColors.textPrimary,
          subtitle: 'Feb 11, 2025',
          subtitleColor: context.aquaColors.textSecondary,
          iconLeading: AquaTransactionIcon.receive(
            colors: context.aquaColors,
          ),
          titleTrailing: '0.04738384',
          titleTrailingColor: context.aquaColors.textPrimary,
          subtitleTrailing: '\$4, 558.51',
          subtitleTrailingColor: context.aquaColors.textSecondary,
          onTap: () {
            ChipSweepTransactionSummarySideSheet.show(
              context: context,
              aquaColors: context.aquaColors,
              loc: context.loc,
            );
          }),
      AquaListItem(
        colors: context.aquaColors,
        title: 'Chip Load',
        titleColor: context.aquaColors.textPrimary,
        subtitle: 'Feb 11, 2025',
        subtitleColor: context.aquaColors.textSecondary,
        iconLeading: AquaTransactionIcon.send(
          colors: context.aquaColors,
        ),
        titleTrailing: '-0.04738384',
        titleTrailingColor: context.aquaColors.textPrimary,
        subtitleTrailing: '-\$4, 558.51',
        subtitleTrailingColor: context.aquaColors.textSecondary,
        onTap: () {
          ChipLoadTransactionSummarySideSheet.show(
            context: context,
            aquaColors: context.aquaColors,
            loc: context.loc,
          );
        },
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        isAutoSwap: true,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.receive(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        iconAssetId: AssetIds.lightning,
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: LightningTransactionSideSheet.send(
            iconAssetId: AssetIds.lightning,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.receive(
            iconAssetId: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.send(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.receive(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        timestamp: tempDate,
        colors: context.aquaColors,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.receive(
            iconAssetId: AssetIds.btc,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: false,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      ////
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: true,
        colors: context.aquaColors,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () => SideSheet.right(
          context: context,
          colors: context.aquaColors,
          body: BasicTransactionSideSheet.swap(
            loc: context.loc,
            fromAssetTicker: AssetIds.btc,
            toAssetTicker: AssetIds.lbtc.first,
            timestamp: tempDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            colors: context.aquaColors,
            isPending: false,
            isFailed: true,
          ),
        ),
      ),
    ];

final mockAddresses = [
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 5
  ),
  (
    address:
        'TTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVqTTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 1
  ),
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 4
  ),
  (address: 'TTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVq', txnCount: 10),
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 2
  ),
  (
    address:
        'TTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVqTTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 1
  ),
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 2
  ),
  (address: 'TTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVq', txnCount: 8),
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 6
  ),
  (
    address:
        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVqVJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 45
  ),
  (
    address:
        'TTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVqTTTTTTTTTTTTTESTNoKREkDiT5QhURJjmAUhE2MpVq',
    txnCount: 5
  ),
];

const testSeedWords = [
  'solar',
  'moon',
  'star',
  'planet',
  'table',
  'tackle',
  'tag',
  'tool',
  'apple',
  'river',
  'mountain',
  'cloud',
  'forest',
  'ocean',
  'stone',
  'leaf',
  'wind',
  'fire',
  'sand',
  'tree',
  'bird',
  'wolf',
  'sky',
  'grass',
  'light',
  'shadow',
  'rain',
  'snow',
  'lake',
  'field',
  'flower',
  'root',
  'seed',
];

const Map<PriceSourceExtra, List<String>> listOfPriceSources = {
  PriceSourceExtra.usd: [
    'Bitfinex',
    'Bitstamp',
    'Coingecko',
    'Kraken',
  ],
  PriceSourceExtra.eur: [
    'Coingecko',
    'Kraken',
  ],
  PriceSourceExtra.cad: [
    'Coingecko',
    'Bullbitcoin',
  ],
};

const List<({Color color, String amount})> denominationBtc = [
  (color: Colors.green, amount: '0.0001 BTC'),
  (color: Colors.red, amount: '0.0005 BTC'),
  (color: Colors.blue, amount: '0.001 BTC'),
  (color: Colors.amber, amount: '0.0025 BTC'),
  (color: Colors.purple, amount: ' 0.01 BTC'),
  (color: Colors.teal, amount: '0.05 BTC'),
];

List<AquaTransactionItem> reservedAmountDolphin(BuildContext context) => [
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
    ];

List<AquaTransactionItem> transactionsDolphin(BuildContext context) => [
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.send(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '-0.04738384',
        amountFiat: '-\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.receive(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
      AquaTransactionItem.swap(
        text: context.loc.transactionItemLocalizations,
        isPending: false,
        isFailed: false,
        fromAssetTicker: 'BTC',
        toAssetTicker: 'L-BTC',
        colors: context.aquaColors,
        timestamp: tempDate,
        amountCrypto: '0.04738384',
        amountFiat: '\$4,558.51',
        onTap: () {},
      ),
    ];

final receiveAssets = <AssetUiModel, List<AssetUiModel>>{
  AssetUiModel(
    assetId: AssetIds.btc,
    name: 'Bitcoin',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.lbtc.first,
    name: 'Liquid Bitcoin',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.lightning,
    name: 'Bitcoin Lightning',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.usdtTether,
    name: 'Tether USDt',
    subtitle: '',
    amount: '11,020.00',
    amountFiat: '',
  ): [
    AssetUiModel(
      assetId:
          'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
      name: 'Liquid USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtEth,
      name: 'Ethereum USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtTrx,
      name: 'Tron USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtBep,
      name: 'Binance USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtSol,
      name: 'Solana USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtPol,
      name: 'Polygon USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtTon,
      name: 'Ton USDt',
      subtitle: '',
      amount: '',
    ),
  ],
};
