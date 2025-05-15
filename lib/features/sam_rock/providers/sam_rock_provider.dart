import 'dart:convert';

import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/features/shared/providers/dio_provider.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/features/wallet/models/subaccounts.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'sam_rock_provider.freezed.dart';

@freezed
class SamRockState with _$SamRockState {
  const factory SamRockState.initial() = _Initial;
  const factory SamRockState.loading() = _Loading;
  const factory SamRockState.error(String message) = _Error;
  const factory SamRockState.success() = _Success;
}

class SamRockStateNotifier extends StateNotifier<SamRockState> {
  SamRockStateNotifier({
    required this.dio,
  }) : super(const SamRockState.initial());

  final Dio dio;

  Future<void> startSetup(
      SamRockAppLink samRockAppLink, Subaccounts subaccounts) async {
    if (subaccounts.subaccounts.length < 3) {
      state = const SamRockState.error('Not enough subaccounts');
      return;
    }
    try {
      state = const SamRockState.loading();
      final bitcoinSubaccount = subaccounts.subaccounts[1];
      final liquidSubaccount = subaccounts.subaccounts[2];
      final testBody = FormData.fromMap({
        'json': jsonEncode({
          "BtcChain": {
            "Xpub": bitcoinSubaccount.exportData,
            "DerivationPath": DerivationPathUtils.formatDerivationPath(
                bitcoinSubaccount.subaccount.userPath),
            "Type": "P2WPKH" // TODO: Get it dynamically
          },
          "LiquidChain": {
            "Xpub": liquidSubaccount.xpub,
            "BlindingKey": liquidSubaccount.blindingKey,
            "DerivationPath": DerivationPathUtils.formatDerivationPath(
                liquidSubaccount.subaccount.userPath),
            "Type": "P2SH_P2WPKH" // TODO: Get it dynamically
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
        throw Exception(
          'Failed to connect to server: ${response.statusCode}',
        );
      }

      state = const SamRockState.success();
    } catch (e) {
      state = SamRockState.error(e.toString());
    }
  }
}

final samRockStateProvider =
    StateNotifierProvider.autoDispose<SamRockStateNotifier, SamRockState>(
  (ref) => SamRockStateNotifier(
    dio: ref.watch(dioProvider),
  ),
);
