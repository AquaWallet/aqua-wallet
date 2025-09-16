import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter/services.dart';

final clipboardContentProvider = FutureProvider.autoDispose<String?>((_) async {
  final content = await Clipboard.getData(Clipboard.kTextPlain);
  return content?.text;
});
