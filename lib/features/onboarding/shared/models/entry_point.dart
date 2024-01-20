import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry_point.freezed.dart';

@freezed
class EntryPoint with _$EntryPoint {
  const factory EntryPoint.home() = EntryPointHome;
  const factory EntryPoint.welcome() = EntryPointWelcome;
  const factory EntryPoint.loading() = EntryPointLoading;
  const factory EntryPoint.error({
    Object? error,
    StackTrace? stackTrace,
  }) = EntryPointError;
}
