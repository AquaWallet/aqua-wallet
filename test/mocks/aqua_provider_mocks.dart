import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockAquaConnectionProvider extends AsyncNotifier<void>
    with Mock
    implements AquaConnectionNotifier {
  @override
  Future<void> connect() async => Future.value(null);
}
