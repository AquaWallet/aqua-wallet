import 'package:aqua/features/sideswap/swap.dart';
import 'package:mocktail/mocktail.dart';

class MockPegStorageProvider extends Mock implements PegOrderStorageNotifier {}

class MockPegOrderStorage extends Mock implements PegOrderStorage {}
