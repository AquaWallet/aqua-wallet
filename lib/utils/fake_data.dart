//NOTE - Mock data for testing and skeleton loading

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:boltz_dart/boltz_dart.dart';

// Assets

List<Asset> get mockAssetsList => [
      Asset(
        id: 'btc',
        name: 'Bitcoin',
        ticker: 'BTC',
        amount: 1000,
        logoUrl: '',
        isUSDt: false,
        isLBTC: false,
      ),
      Asset(
        id: 'lbtc',
        name: 'Liquid Bitcoin',
        ticker: 'L-BTC',
        amount: 1000,
        logoUrl: '',
        isUSDt: false,
        isLBTC: true,
      ),
      Asset(
        id: 'usdt',
        name: 'Tether USD',
        ticker: 'USDt',
        amount: 1000,
        logoUrl: '',
        isUSDt: true,
        isLBTC: false,
      ),
    ];

// Transactions

final kMockDbTransactions = [
  const TransactionDbModel(
    id: 1,
    txhash: 'hashPegIn',
    serviceOrderId: 'orderPegIn',
    receiveAddress: 'addressPegIn',
    assetId: 'assetPegIn',
    type: TransactionDbModelType.sideswapPegIn,
  ),
  const TransactionDbModel(
    id: 2,
    txhash: 'hashSideswapPegOut',
    serviceOrderId: 'orderSideswapPegOut',
    receiveAddress: 'addressSideswapPegOut',
    assetId: 'assetSideswapPegOut',
    type: TransactionDbModelType.sideswapPegOut,
  ),
  const TransactionDbModel(
    id: 3,
    txhash: 'hashBoltzSwap',
    serviceOrderId: 'orderBoltzSwap',
    receiveAddress: 'addressBoltzSwap',
    assetId: 'assetBoltzSwap',
    type: TransactionDbModelType.boltzSwap,
  ),
  const TransactionDbModel(
    id: 4,
    txhash: 'hashBoltzReverseSwap',
    serviceOrderId: 'orderBoltzReverseSwap',
    receiveAddress: 'addressBoltzReverseSwap',
    assetId: 'assetBoltzReverseSwap',
    type: TransactionDbModelType.boltzReverseSwap,
  ),
  const TransactionDbModel(
    id: 5,
    txhash: 'hashSideswapSwap',
    serviceOrderId: 'orderSideswapSwap',
    receiveAddress: 'addressSideswapSwap',
    assetId: 'assetSideswapSwap',
    type: TransactionDbModelType.sideswapSwap,
  ),
  const TransactionDbModel(
    id: 6,
    txhash: 'hashSideshiftSwap',
    serviceOrderId: 'orderSideshiftSwap',
    receiveAddress: 'addressSideshiftSwap',
    assetId: 'assetSideshiftSwap',
    type: TransactionDbModelType.sideshiftSwap,
  ),
];

// Sideshift Orders

final kMockDbSideshiftOrders = [
  SideshiftOrderDbModel(
    orderId: 'sideshiftOrder1',
    createdAt: DateTime(2023, 1, 1),
    depositCoin: 'BTC',
    settleCoin: 'USDT',
    depositNetwork: 'Bitcoin',
    settleNetwork: 'Liquid',
    depositAddress: 'btcAddress1',
    settleAddress: 'liquidAddress1',
    depositMin: '0.001',
    depositMax: '1.0',
    type: OrderType.fixed,
    depositAmount: '0.1',
    settleAmount: '3000',
    expiresAt: DateTime(2023, 1, 2),
    status: OrderStatus.pending,
    updatedAt: DateTime(2023, 1, 1, 12),
    depositHash: 'depositHash1',
    settleHash: 'settleHash1',
    depositReceivedAt: DateTime(2023, 1, 1, 12, 30),
    rate: '30000',
    onchainTxHash: 'onchainTxHash1',
  ),
  SideshiftOrderDbModel(
    orderId: 'sideshiftOrder2',
    createdAt: DateTime(2023, 2, 1),
    depositCoin: 'ETH',
    settleCoin: 'BTC',
    depositNetwork: 'Ethereum',
    settleNetwork: 'Bitcoin',
    depositAddress: 'ethAddress1',
    settleAddress: 'btcAddress2',
    depositMin: '0.01',
    depositMax: '10.0',
    type: OrderType.variable,
    depositAmount: '1.0',
    settleAmount: '0.05',
    expiresAt: DateTime(2023, 2, 2),
    status: OrderStatus.settled,
    updatedAt: DateTime(2023, 2, 1, 14),
    depositHash: 'depositHash2',
    settleHash: 'settleHash2',
    depositReceivedAt: DateTime(2023, 2, 1, 14, 30),
    rate: '0.05',
    onchainTxHash: 'onchainTxHash2',
  ),
];

final kMockDbBoltzSwaps = [
  const BoltzSwapDbModel(
    boltzId: 'boltzId1',
    kind: SwapType.submarine,
    network: Chain.liquid,
    hashlock: 'hashlock1',
    receiverPubkey: 'receiverPubkey1',
    senderPubkey: 'senderPubkey1',
    invoice: 'invoice1',
    outAmount: 0,
    blindingKey: 'blindingKey1',
    locktime: 100,
    scriptAddress: 'scriptAddress1',
  ),
  const BoltzSwapDbModel(
    boltzId: 'boltzId2',
    kind: SwapType.submarine,
    network: Chain.bitcoin,
    hashlock: 'hashlock2',
    receiverPubkey: 'receiverPubkey2',
    senderPubkey: 'senderPubkey2',
    invoice: 'invoice2',
    outAmount: 100,
    blindingKey: 'blindingKey2',
    locktime: 0,
    scriptAddress: 'scriptAddress2',
  ),
  const BoltzSwapDbModel(
    boltzId: 'boltzId3',
    kind: SwapType.reverse,
    network: Chain.liquid,
    hashlock: 'hashlock3',
    receiverPubkey: 'receiverPubkey3',
    senderPubkey: 'senderPubkey3',
    invoice: 'invoice3',
    outAmount: 0,
    blindingKey: 'blindingKey3',
    locktime: 100,
    scriptAddress: 'scriptAddress3',
  ),
  const BoltzSwapDbModel(
    boltzId: 'boltzId4',
    kind: SwapType.reverse,
    network: Chain.bitcoin,
    hashlock: 'hashlock4',
    receiverPubkey: 'receiverPubkey4',
    senderPubkey: 'senderPubkey4',
    invoice: 'invoice4',
    outAmount: 100,
    blindingKey: 'blindingKey4',
    locktime: 0,
    scriptAddress: 'scriptAddress4',
  ),
];
