import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/receive_address/receive_address_ui_model.dart';
import 'package:aqua/data/provider/receive_address/receive_addresses_history_arguments.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class UsedAdresses {
  GdkTransaction transaction;
  List<GdkPreviousAddress> addresses;

  UsedAdresses({
    required this.transaction,
    required this.addresses,
  });
}

final receiveAddressProvider = Provider.family
    .autoDispose<ReceiveAddressProvider, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) => ReceiveAddressProvider(ref, arguments));

class ReceiveAddressProvider {
  final AutoDisposeProviderRef ref;
  final ReceiveAddressesHistoryArguments? arguments;

  ReceiveAddressProvider(this.ref, this.arguments);

  final PublishSubject<void> _reloadSubject = PublishSubject();

  late final Stream<AsyncValue<(Asset, List<GdkTransaction>)>> _dataStream =
      _reloadSubject
          .startWith(null)
          .switchMap((_) => Stream.value(_)
              .map((_) {
                if (arguments is ReceiveAddressesHistoryArguments) {
                  return (arguments as ReceiveAddressesHistoryArguments).asset;
                }
                throw ReceiveAddressInvalidArgumentsException();
              })
              .switchMap((asset) => Stream.value(asset)
                  .switchMap((asset) => asset.isBTC
                      ? ref.read(bitcoinProvider).transactionEventSubject.startWith(null).asyncMap(
                          (_) => ref.read(bitcoinProvider).getTransactions())
                      : ref.read(liquidProvider).transactionEventSubject.startWith(null).asyncMap(
                          (_) => ref.read(liquidProvider).getTransactions()))
                  .map((transactions) => transactions
                      ?.where((transaction) =>
                          transaction.satoshi?[asset.id] != null &&
                          GdkTransactionTypeEnum.incoming == transaction.type)
                      .toList())
                  .map((transactions) => transactions ?? [])
                  .map((transactions) => (asset, transactions)))
              .map((transactions) => AsyncValue.data(transactions))
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith((error, stackTrace) => AsyncValue.error(error, stackTrace)))
          .shareReplay(maxSize: 1);

  late final Stream<AsyncValue<(Asset, List<UsedAdresses>)>>
      _usedAddressesStream = _dataStream
          .switchMap((value) => value.when(
                data: (item) {
                  return Stream.value(item.$1).switchMap((asset) =>
                      Stream.value(item.$2).switchMap((transactions) =>
                          Stream.value(null).asyncMap((_) async {
                            final allAddresses = asset.isBTC
                                ? await ref
                                    .read(bitcoinProvider)
                                    .getAllPreviousAddresses()
                                : await ref
                                    .read(liquidProvider)
                                    .getAllPreviousAddresses();

                            return allAddresses;
                          }).switchMap(
                            (allAddresses) => Stream.value(allAddresses)
                                .map((_) {
                                  final usedAddresses = <UsedAdresses>[];
                                  for (var transaction in transactions) {
                                    final addresses = asset.isBTC
                                        ? ref
                                            .read(bitcoinProvider)
                                            .getUsedAddresses(
                                                [transaction], allAddresses)
                                        : ref
                                            .read(liquidProvider)
                                            .getUsedAddresses(
                                                [transaction], allAddresses);

                                    usedAddresses.add(UsedAdresses(
                                        transaction: transaction,
                                        addresses: addresses));
                                  }

                                  return (asset, usedAddresses);
                                })
                                .map((data) => AsyncValue.data(data))
                                .startWith(const AsyncValue.loading())
                                .onErrorReturnWith((error, stackTrace) =>
                                    AsyncValue.error(error, stackTrace)),
                          )));
                },
                loading: () {
                  return Stream.value(
                      const AsyncValue<(Asset, List<UsedAdresses>)>.loading());
                },
                error: (error, stackTrace) => Stream.value(
                    AsyncValue<(Asset, List<UsedAdresses>)>.error(
                        error, stackTrace)),
              ))
          .shareReplay(maxSize: 1);

  Stream<ReceiveAddressUiModel> _usedAddressUiModelStream() =>
      _usedAddressesStream.asyncMap((value) => value.when(
          data: (data) => Stream.fromIterable(data.$2)
              .asyncMap((usedAddress) async {
                final asset = data.$1;
                final date = usedAddress.transaction.createdAtTs != null
                    ? DateFormat.yMMMd().format(
                        DateTime.fromMicrosecondsSinceEpoch(
                            usedAddress.transaction.createdAtTs!))
                    : '';
                final amount = usedAddress.transaction.satoshi == null
                    ? 0
                    : usedAddress.transaction.satoshi!.containsKey(asset.id) ==
                            true
                        ? usedAddress.transaction.satoshi![asset.id] as int
                        : 0;
                final formattedAmount =
                    ref.read(formatterProvider).signedFormatAssetAmount(
                          amount: amount,
                          precision: asset.precision,
                        );
                final amountText = '$formattedAmount ${asset.ticker}';
                final transactionId = usedAddress.transaction.txhash ?? '';
                final addresses =
                    usedAddress.addresses.map((e) => e.address ?? '').toList();

                return ReceiveUsedAddressItemUiModel(
                  addresses: addresses,
                  date: date,
                  amount: amountText,
                  network: asset.isLBTC ? 'Liquid' : 'Bitcoin',
                  transactionId: transactionId,
                );
              })
              .toList()
              .then<ReceiveAddressUiModel>((itemUiModels) =>
                  ReceiveUsedAddressUiModel(itemUiModels: itemUiModels))
              .onError((error, stackTrace) =>
                  ReceiveAddressErrorUiModel(buttonAction: () {
                    _reloadSubject.add(null);
                  })),
          loading: () => Future.value(const ReceiveAddressLoadingUiModel()),
          error: (error, stackTrace) =>
              Future.value(ReceiveAddressErrorUiModel(buttonAction: () {
                _reloadSubject.add(null);
              }))));

  late final Stream<AsyncValue<List<GdkPreviousAddress>>> _allAddressesStream =
      _dataStream.switchMap((value) => value.when(
            data: (item) => Stream.value(item.$1)
                .switchMap((asset) => Stream.value(null).asyncMap((_) async {
                      return asset.isBTC
                          ? ref.read(bitcoinProvider).getAllPreviousAddresses()
                          : ref.read(liquidProvider).getAllPreviousAddresses();
                    }))
                .map((data) => AsyncValue.data(data))
                .startWith(const AsyncValue.loading())
                .onErrorReturnWith(
                    (error, stackTrace) => AsyncValue.error(error, stackTrace)),
            loading: () => Stream.value(
                const AsyncValue<List<GdkPreviousAddress>>.loading()),
            error: (error, stackTrace) => Stream.value(
                AsyncValue<List<GdkPreviousAddress>>.error(error, stackTrace)),
          ));

  Stream<ReceiveAddressUiModel> _allAddressesUiModelStream() =>
      _allAddressesStream.asyncMap((value) => value.when(
          data: (data) => Stream.fromIterable(data)
              .map((gdkPreviousAddress) {
                return ReceiveAllAddressItemUiModel(
                  address: gdkPreviousAddress.address ?? '',
                  addressType: gdkPreviousAddress.addressType ?? '',
                  txCount: gdkPreviousAddress.txCount ?? 0,
                  date: '',
                );
              })
              .toList()
              .then<ReceiveAddressUiModel>((allUiModel) {
                return _usedAddressUiModelStream()
                    .map<ReceiveAddressUiModel>((usedUiModel) {
                  return usedUiModel.maybeWhen(
                    usedAddresses: (usedItems) {
                      for (var e in usedItems) {
                        for (var a in e.addresses) {
                          final index = allUiModel
                              .indexWhere((element) => element.address == a);
                          if (index >= 0) {
                            final newAllItem =
                                allUiModel[index].copyWith(date: e.date);
                            allUiModel[index] = newAllItem;
                          }
                        }
                      }

                      allUiModel.sort((a, b) {
                        return b.date.compareTo(a.date);
                      });

                      return ReceiveAllAddressesUiModel(
                          itemUiModels: allUiModel);
                    },
                    orElse: () {
                      return ReceiveAllAddressesUiModel(
                          itemUiModels: allUiModel);
                    },
                  );
                }).first;
              })
              .onError((error, stackTrace) =>
                  ReceiveAddressErrorUiModel(buttonAction: () {
                    _reloadSubject.add(null);
                  })),
          loading: () => Future.value(const ReceiveAddressLoadingUiModel()),
          error: (error, stackTrace) =>
              Future.value(ReceiveAddressErrorUiModel(buttonAction: () {
                _reloadSubject.add(null);
              }))));

  final _searchQuerySubject = PublishSubject<String>();

  void search(String query) {
    _searchQuerySubject.add(query);
  }
}

final _receiveUsedAddressesUiModelStreamProvider = StreamProvider.family
    .autoDispose<ReceiveAddressUiModel, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) async* {
  yield* ref
      .watch(receiveAddressProvider(arguments))
      ._usedAddressUiModelStream();
});

final receiveAddressesUiModelProvider = Provider.family
    .autoDispose<ReceiveAddressUiModel?, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) {
  return ref
      .watch(_receiveUsedAddressesUiModelStreamProvider(arguments))
      .asData
      ?.value;
});

final _receiveAllAddressesUiModelStreamProvider = StreamProvider.family
    .autoDispose<ReceiveAddressUiModel, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) async* {
  yield* ref
      .watch(receiveAddressProvider(arguments))
      ._allAddressesUiModelStream();
});

final receiveAllAddressesUiModelProvider = Provider.family
    .autoDispose<ReceiveAddressUiModel?, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) {
  return ref
      .watch(_receiveAllAddressesUiModelStreamProvider(arguments))
      .asData
      ?.value;
});

final _receiveAddressSearchQueryStreamProvider = StreamProvider.family
    .autoDispose<String, ReceiveAddressesHistoryArguments?>(
        (ref, arguments) async* {
  yield* ref
      .watch(receiveAddressProvider(arguments))
      ._searchQuerySubject
      .stream
      .map((s) => s.toLowerCase());
});

final receiveAddressSearchQueryProvider = Provider.family
    .autoDispose<String, ReceiveAddressesHistoryArguments?>((ref, arguments) {
  return ref
          .watch(_receiveAddressSearchQueryStreamProvider(arguments))
          .asData
          ?.value ??
      '';
});

final receiveAddressChipsState =
    StateProvider.autoDispose<ReceiveAddressChipsState>(
        (ref) => const ReceiveAddressChipsStateUsed());

class ReceiveAddressInvalidArgumentsException implements Exception {}
