import 'package:coin_cz/features/scan/models/scan_arguments.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/features/shared/shared.dart';

class ToggleButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isSelected;
  const ToggleButton(
      {required this.onTap,
      required this.label,
      required this.isSelected,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? context.colors.activeButtonToggle
            : context.colors.inactiveButtonToggle,
        border: Border.all(
          color: context.colors.toggleBorder,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              // Change text style that already exists
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToggleBar extends StatelessWidget {
  final ScannerType selectedType;
  final ValueChanged<ScannerType> onTypeChanged;
  const ToggleBar({
    required this.selectedType,
    required this.onTypeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: context.colors.toggleBorder,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: ToggleButton(
              isSelected: selectedType == ScannerType.qr,
              label: context.loc.scanQrCodeTitle,
              onTap: () => onTypeChanged(ScannerType.qr),
            ),
          ),
          Expanded(
            child: ToggleButton(
              isSelected: selectedType == ScannerType.text,
              label: context.loc.scanTextTitle,
              onTap: () => onTypeChanged(ScannerType.text),
            ),
          ),
        ],
      ),
    );
  }
}
