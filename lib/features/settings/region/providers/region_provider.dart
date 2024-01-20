import 'dart:convert';

import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:async/async.dart';
import 'package:flutter/services.dart';

Future<Result<RegionResponse>> fetchRegions(
    AutoDisposeFutureProviderRef ref) async {
  try {
    final fetchedRegionsResponse =
        await ref.read(dioProvider).get(urls.regionsUrl);
    final regionsJson = fetchedRegionsResponse.data as Map<String, dynamic>;
    final response = RegionResponse.fromJson(regionsJson);
    logger.i(
        '[availableRegionsProvider] Fetched ${response.data?.regions.length} regions');

    return Result.value(response);
  } catch (e) {
    logger.w('[availableRegionsProvider] Failed to fetch regions');
    return Result.error(e);
  }
}

final availableRegionsProvider =
    FutureProvider.autoDispose<List<Region>>((ref) async {
  final keepAliveLink = ref.keepAlive();
  Future.delayed(const Duration(hours: 1), () => keepAliveLink.close());

  final staticRegionsJson =
      await json.decode(await rootBundle.loadString('assets/regions.json'));
  final fetchedRegionsJson = await fetchRegions(ref);

  final regions = fetchedRegionsJson.asValue?.value.data!.regions ??
      RegionResponse.fromJson(staticRegionsJson).data!.regions;
  logger.i('[availableRegionsProvider] Set regions: ${regions.length}');
  return regions;
});

final regionsProvider = Provider.autoDispose<RegionsProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  return RegionsProvider(prefs);
});

class RegionsProvider extends ChangeNotifier {
  RegionsProvider(this.prefs);

  final UserPreferencesNotifier prefs;

  Region? get currentRegion {
    return prefs.region != null
        ? Region.fromJson(jsonDecode(prefs.region!) as Map<String, dynamic>)
        : null;
  }

  bool get regionRequired => currentRegion == null;

  Future<void> setRegion(Region region) async {
    prefs.setRegion(jsonEncode(region.toJson()));
    notifyListeners();
  }

  Future<void> setRegionRequired() async {
    prefs.removeRegion();
    notifyListeners();
  }
}
