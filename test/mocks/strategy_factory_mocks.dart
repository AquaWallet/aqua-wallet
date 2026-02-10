import 'package:aqua/features/transactions/transactions.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionStrategyFactory extends Mock
    implements TransactionStrategyFactory {}

class MockTransactionTypeStrategy extends Mock
    implements TransactionUiModelCreator {}
