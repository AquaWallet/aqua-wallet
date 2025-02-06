import 'dart:async';

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetsNotifier extends AsyncNotifier<List<Asset>>
    with Mock
    implements AssetsNotifier {
  MockAssetsNotifier({required this.assets});

  final List<Asset> assets;

  @override
  FutureOr<List<Asset>> build() => assets;
}
