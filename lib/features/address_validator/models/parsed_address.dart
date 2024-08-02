import 'package:aqua/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_address.freezed.dart';

@freezed
class ParsedAddress with _$ParsedAddress {
  factory ParsedAddress({
    required String address,
    Decimal? amount,
    Asset? asset,
    String? assetId,
    String? message,
    String? label,
    String? lightningInvoice,
    LNURLParseResult? lnurlParseResult,
  }) = _ParsedAddress;
}
