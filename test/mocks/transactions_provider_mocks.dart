import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<TransactionUiModel>, Asset>
    with Mock
    implements TransactionsNotifier {
  MockTransactionsNotifier({required this.transactions});

  final List<TransactionUiModel> transactions;

  @override
  Future<List<TransactionUiModel>> build(Asset arg) async => transactions;
}

class MockNetworkTransactionsNotifier extends Mock {
  MockNetworkTransactionsNotifier({this.transactions = const []});

  final List<GdkTransaction> transactions;

  Stream<List<GdkTransaction>> call(Asset asset) => Stream.value(transactions);
}
