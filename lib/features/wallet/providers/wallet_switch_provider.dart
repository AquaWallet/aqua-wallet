import 'package:aqua/features/shared/shared.dart';

// Enum to represent different wallet operation states
enum WalletOperationState {
  idle,
  switching,
}

// Provider to track wallet operation state
final walletOperationProvider =
    StateProvider<WalletOperationState>((ref) => WalletOperationState.idle);
