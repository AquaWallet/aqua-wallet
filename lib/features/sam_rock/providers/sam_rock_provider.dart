import 'dart:convert';
import 'dart:async';

import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/sam_rock/models/sam_rock_exception.dart';
import 'package:aqua/features/shared/providers/dio_provider.dart';
import 'package:aqua/features/wallet/models/subaccounts.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  Future<List<String>> _fetchUniqueLiquidAddresses(Ref ref, int count) async {
    final liquidAddresses = <String>[];
    for (int i = 0; i < count; i++) {
      final receiveAddressDetails =
          await ref.read(liquidProvider).getReceiveAddress();
      if (receiveAddressDetails?.address != null &&
          !liquidAddresses.contains(receiveAddressDetails!.address)) {
        liquidAddresses.add(receiveAddressDetails.address!);
      } else {
        if (i > 0 && liquidAddresses.length < i + 1) {
          // Avoid infinite loop if GDK keeps returning same/null addresses
          throw SamRockException(SamRockExceptionType.generic,
              customMessage:
                  "Could not generate $count unique Liquid addresses.");
        }
        i--;
      }
      if (liquidAddresses.length == count) break;
    }

    if (liquidAddresses.length < count) {
      throw SamRockException(SamRockExceptionType.generic,
          customMessage: "Failed to retrieve $count unique Liquid addresses.");
    }
    return liquidAddresses;
  }

  Future<void> startSetup(
    SamRockAppLink samRockAppLink,
    Subaccounts subaccounts,
  ) async {
    try {
      await _performUpload(samRockAppLink, subaccounts);
    } on SamRockException catch (e) {
      state = SamRockState.error(e);
    } catch (e) {
      state = SamRockState.error(SamRockException(SamRockExceptionType.generic,
          customMessage: e.toString()));
    }
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
      //TODO: Temp getting fingerprint from leagcy mnemonic. Resolve with using storedWalletsProvider when multiwallet is merged
      final (mnemonic, err) =
          await ref.read(secureStorageProvider).get(StorageKeys.mnemonic);
      if (err != null || mnemonic == null) {
        throw SamRockException(SamRockExceptionType.missingWalletData,
            customMessage: 'Failed to retrieve mnemonic: $err');
      }

      if (subaccounts.subaccounts.length < 3) {
        throw SamRockException(SamRockExceptionType.notEnoughSubaccounts);
      }

      state = const SamRockState.loading();
      final bitcoinSubaccount = subaccounts.subaccounts[1];
      final liquidSubaccount = subaccounts.subaccounts[2];

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
