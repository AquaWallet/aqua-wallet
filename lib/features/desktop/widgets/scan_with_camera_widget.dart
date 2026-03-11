import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class ScanWidget extends StatelessWidget {
  const ScanWidget({
    super.key,
    required this.aquaColors,
    required this.onScanned,
    required this.onClose,
  });

  final AquaColors aquaColors;
  final ValueChanged<String> onScanned;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AquaText.body1SemiBold(
                text: 'Scan QR Code',
                color: aquaColors.textPrimary,
              ),
              InkWell(
                onTap: onClose,
                child: AquaIcon.close(
                  color: aquaColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Scanner placeholder (replace with actual scanner)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: aquaColors.surfaceBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: aquaColors.surfaceBorderSecondary,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AquaIcon.scan(
                    color: aquaColors.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  AquaText.body2(
                    text: 'Point camera at QR code',
                    color: aquaColors.textSecondary,
                  ),
                  const SizedBox(height: 16),

                  // Mock scan button for testing
                  AquaButton.utility(
                    text: 'Simulate Scan',
                    onPressed: () {
                      // Simulate scanning a Bitcoin address
                      onScanned('bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
