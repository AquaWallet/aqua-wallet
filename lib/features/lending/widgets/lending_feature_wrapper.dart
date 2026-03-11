import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/lending/services/lending_service.dart';
import 'package:aqua/features/private_integrations/lend_a_sat/services/lend_a_sat_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A wrapper widget that provides the LendASat adapter to the entire lending feature.
/// This ensures that the service is available to all screens in the lending feature.
class LendingFeatureWrapper extends ConsumerWidget {
  final Widget child;

  const LendingFeatureWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lendASatAdapter = ref.watch(lendASatAdapterProvider);

    return ProviderScope(
      overrides: [
        // Override the service provider with the LendASat adapter
        lendingServiceProvider.overrideWithValue(lendASatAdapter),
        // Force the lendingProvider to be recreated with the new service
        lendingProvider.overrideWith(() => LendingNotifier()),
      ],
      child: child,
    );
  }
}
