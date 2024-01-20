import 'dart:convert';

import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

//ANCHOR - Convenience Providers

/// FutureProvider to fetch all cached orders
final sideShiftCachedOrdersProvider =
    FutureProvider.autoDispose<List<SideshiftOrderStatusResponse>?>(
        (ref) async {
  return ref.watch(sideshiftStorageProvider).getAllSideshiftOrders();
});

//ANCHOR - Main Provider
final sideshiftStorageProvider = Provider<SideshiftStorageProvider>((ref) {
  return SideshiftStorageProvider(ref);
});

class SideshiftStorageProvider {
  final ProviderRef ref;

  SideshiftStorageProvider(this.ref);

  final _prefs = SharedPreferences.getInstance();

  static const String _orderPrefix = 'sideshiftOrder_';

  //ANCHOR - Save
  Future<void> saveSideshiftOrderData(
      SideshiftOrderStatusResponse order, String id) async {
    if (id.isEmpty) {
      return;
    }

    SharedPreferences prefs = await _prefs;
    prefs.setString('$_orderPrefix$id', jsonEncode(order.toJson()));
  }

  //ANCHOR - Retrieve Single Order
  Future<SideshiftOrderStatusResponse?> getSideshiftOrderData(String id) async {
    SharedPreferences prefs = await _prefs;
    String? sideshiftOrderJson = prefs.getString('$_orderPrefix$id');

    if (sideshiftOrderJson != null) {
      Map<String, dynamic> json = jsonDecode(sideshiftOrderJson);
      SideshiftOrderStatusResponse order =
          SideshiftOrderStatusResponse.fromJson(json);

      logger.d("[Sideshift] fetched order from storage: $order");
      return order;
    }

    return null;
  }

  //ANCHOR - Retrieve All Orders
  Future<List<SideshiftOrderStatusResponse>> getAllSideshiftOrders() async {
    SharedPreferences prefs = await _prefs;
    final keys = prefs.getKeys();
    List<SideshiftOrderStatusResponse> orders = [];

    for (String key in keys) {
      if (key.startsWith(_orderPrefix)) {
        String? orderJson = prefs.getString(key);
        if (orderJson != null) {
          Map<String, dynamic> json = jsonDecode(orderJson);
          SideshiftOrderStatusResponse order =
              SideshiftOrderStatusResponse.fromJson(json);
          orders.add(order);
        }
      }
    }

    // sort by `createdAt`
    orders.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return orders;
  }

  //ANCHOR - Updates
  Future<void> updateOrderStatus(String id, OrderStatus newStatus) async {
    if (id.isEmpty) {
      return;
    }

    SharedPreferences prefs = await _prefs;
    String? orderJson = prefs.getString('$_orderPrefix$id');

    if (orderJson != null) {
      Map<String, dynamic> json = jsonDecode(orderJson);
      SideshiftOrderStatusResponse order =
          SideshiftOrderStatusResponse.fromJson(json);

      order = order.copyWith(status: newStatus);
      prefs.setString('$_orderPrefix$id', jsonEncode(order.toJson()));
      logger.d(
          "[Sideshift] Updated order status in storage: ${order.id} - status: ${order.status.toString()}");
    }
  }

  Future<void> updateTxHash(String id, String txHash) async {
    if (id.isEmpty) {
      return;
    }

    SharedPreferences prefs = await _prefs;
    String? orderJson = prefs.getString('$_orderPrefix$id');

    if (orderJson != null) {
      Map<String, dynamic> json = jsonDecode(orderJson);
      SideshiftOrderStatusResponse order =
          SideshiftOrderStatusResponse.fromJson(json);

      order = order.copyWith(onchainTxHash: txHash);
      prefs.setString('$_orderPrefix$id', jsonEncode(order.toJson()));
      logger.d(
          "[Sideshift] Updated order status in storage: ${order.id} - txHash: ${order.onchainTxHash}");
    }
  }

  //ANCHOR - Delete
  Future<void> deleteSideshiftOrderData(String id) async {
    SharedPreferences prefs = await _prefs;
    prefs.remove('$_orderPrefix$id');
  }
}
