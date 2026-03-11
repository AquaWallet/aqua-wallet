import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the currently selected offer ID
final selectedOfferIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the currently selected contract ID
final selectedContractIdProvider = StateProvider<String?>((ref) => null);
