import 'package:aqua/features/shared/shared.dart';

// Used to represent a service in the marketplace
// Corresponds to a MarketplaceButton in the UI
class MarketplaceService {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onPressed;

  const MarketplaceService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });
}
