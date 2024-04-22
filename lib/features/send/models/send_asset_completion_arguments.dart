import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_completion_arguments.freezed.dart';

@freezed
class SendAssetCompletionArguments with _$SendAssetCompletionArguments {
  const factory SendAssetCompletionArguments({
    int? timestamp,
    String? txId,
  }) = _SendAssetCompletionArguments;
}
