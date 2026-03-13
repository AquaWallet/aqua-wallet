import 'dart:async';
import 'dart:convert';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/sam_rock/models/sam_rock_exception.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sam_rock_provider.freezed.dart';

const kSamRockWalletDefaultName = "SamRock Wallet";

@freezed
class SamRockState with _$SamRockState {
  const factory SamRockState.initial() = _Initial;
  const factory SamRockState.loading() = _Loading;
  const factory SamRockState.error(SamRockException exception) = _Error;
  const factory SamRockState.success() = _Success;
  const factory SamRockState.requiresNewWalletConfirmation(
      SamRockAppLink appLink) = _RequiresNewWalletConfirmation;
}

class SamRockStateNotifier extends StateNotifier<SamRockState> {
  SamRockStateNotifier({
    required this.dio,
    required this.ref,
  }) : super(const SamRockState.initial());

  static const _payloadVersion = "1.0";

  final Dio dio;
  final Ref ref;

  Future<void> startSetup(
    SamRockAppLink samRockAppLink,
    Subaccounts subaccounts,
  ) async {
    try {
      final currentWallet =
          ref.read(storedWalletsProvider).value?.currentWallet;
      if (currentWallet == null) {
        throw SamRockException(SamRockExceptionType.missingWalletData);
      }

      final btcTxs = await ref.read(bitcoinProvider).getTransactions();
      final liquidTxs = await ref.read(liquidProvider).getTransactions();

      final bool hasTransactions = (btcTxs != null && btcTxs.isNotEmpty) ||
          (liquidTxs != null && liquidTxs.isNotEmpty);

      if (hasTransactions) {
        state = SamRockState.requiresNewWalletConfirmation(samRockAppLink);
        return;
      } else {
        await _performUpload(samRockAppLink, subaccounts);
      }
    } on SamRockException catch (e) {
      state = SamRockState.error(e);
    } catch (e) {
      state = SamRockState.error(SamRockException(SamRockExceptionType.generic,
          customMessage: e.toString()));
    }
  }

  Future<void> confirmWalletCreation(SamRockAppLink appLink) async {
    try {
      state = const SamRockState.loading();

      // Trigger wallet registration
      await ref.read(storedWalletsProvider.notifier).addWallet(
            name: kSamRockWalletDefaultName,
            samRockAppLink: appLink,
            operationType: WalletOperationType.create,
          );

      // Allow time for wallet creation and state updates (simplistic approach)
      await Future.delayed(const Duration(seconds: 1));

      final newWalletState = ref.read(storedWalletsProvider).value;
      final newWalletId = newWalletState?.currentWallet?.id;

      if (newWalletId == null) {
        // It's possible the wallet wasn't created/switched in time
        throw SamRockException(SamRockExceptionType.failedToGetNewWalletState);
      }

      // Invalidate subaccounts provider to load for the new wallet
      ref.invalidate(subaccountsProvider);
      await ref.read(subaccountsProvider.notifier).loadSubaccounts();
      final newSubaccounts = ref.read(subaccountsProvider).valueOrNull;
      if (newSubaccounts == null) {
        throw SamRockException(SamRockExceptionType.notEnoughSubaccounts);
      }

      await _performUpload(appLink, newSubaccounts);
    } on SamRockException catch (e) {
      state = SamRockState.error(e);
    } catch (e) {
      state = SamRockState.error(SamRockException(SamRockExceptionType.generic,
          customMessage:
              "Failed during wallet creation process: ${e.toString()}"));
    }
  }

  Future<void> cancelWalletCreation(
    SamRockAppLink appLink,
    Subaccounts currentSubaccounts,
  ) async {
    await _performUpload(appLink, currentSubaccounts);
  }

  Future<void> _performUpload(
    SamRockAppLink samRockAppLink,
    Subaccounts subaccounts,
  ) async {
    if (samRockAppLink.isMock) {
      state = const SamRockState.loading();
      await Future.delayed(const Duration(seconds: 2));
      state = const SamRockState.success();
      return;
    }

    try {
      final walletFingerprint =
          ref.read(storedWalletsProvider).value?.currentWallet?.id;
      if (walletFingerprint == null) {
        throw SamRockException(SamRockExceptionType.missingWalletData);
      }

      state = const SamRockState.loading();
      final bitcoinSubaccounts = subaccounts.subaccounts
          .where((s) => s.networkType == NetworkType.bitcoin)
          .toList();
      final liquidSubaccounts = subaccounts.subaccounts
          .where((s) => s.networkType == NetworkType.liquid)
          .toList();
      if (bitcoinSubaccounts.isEmpty || liquidSubaccounts.isEmpty) {
        throw SamRockException(SamRockExceptionType.notEnoughSubaccounts);
      }
      final bitcoinSubaccount = bitcoinSubaccounts.firstWhere(
        (s) => s.subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh,
        orElse: () => bitcoinSubaccounts.first,
      );
      final liquidSubaccount = liquidSubaccounts.first;

      // Get the core descriptors for the Liquid subaccount
      final liquidCoreDescriptors = liquidSubaccount.subaccount.coreDescriptors;
      if (liquidCoreDescriptors == null || liquidCoreDescriptors.isEmpty) {
        throw SamRockException(SamRockExceptionType.missingWalletData,
            customMessage: 'Liquid subaccount core descriptors are missing.');
      }
      // assuming the first descriptor is the CtDescriptor
      final ctDescriptor = liquidCoreDescriptors[0];

      // Get the core descriptors for the Bitcoin subaccount
      final bitcoinCoreDescriptors =
          bitcoinSubaccount.subaccount.coreDescriptors;
      if (bitcoinCoreDescriptors == null || bitcoinCoreDescriptors.isEmpty) {
        throw SamRockException(SamRockExceptionType.missingWalletData,
            customMessage: 'Bitcoin subaccount core descriptors are missing.');
      }
      // assuming the first descriptor is the Descriptor
      final btcDescriptor = bitcoinCoreDescriptors[0];

      final testBody = FormData.fromMap({
        'json': jsonEncode({
          "version": _payloadVersion,
          "BTC": {"Descriptor": btcDescriptor},
          "LBTC": {"Descriptor": ctDescriptor},
          "BTC-LN": {
            "Type": "boltz",
            "LBTC": {"Descriptor": ctDescriptor}
          }
        })
      });

      final response = await dio.post(
        samRockAppLink.uploadUrl,
        data: testBody,
        options: Options(
          contentType: 'application/json; charset=utf-8',
        ),
      );

      if (response.statusCode != 200) {
        throw SamRockException(SamRockExceptionType.connectionFailed,
            customMessage: 'Server responded with ${response.statusCode}');
      }

      state = const SamRockState.success();
    } on SamRockException catch (e) {
      state = SamRockState.error(e);
    } catch (e) {
      state = SamRockState.error(SamRockException(SamRockExceptionType.generic,
          customMessage: e.toString()));
    }
  }
}

final samRockStateProvider =
    StateNotifierProvider.autoDispose<SamRockStateNotifier, SamRockState>(
  (ref) => SamRockStateNotifier(
    dio: ref.watch(dioProvider),
    ref: ref,
  ),
);
