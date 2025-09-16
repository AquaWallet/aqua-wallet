import 'package:coin_cz/features/scan/models/scan_arguments.dart';
import 'package:coin_cz/features/qr_scan/qr_scan.dart';
import 'package:coin_cz/features/scan/widgets/toggle_bar_widget.dart';
import 'package:coin_cz/features/text_scan/text_scan.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScanScreen extends HookWidget {
  static const routeName = '/scanScreen';
  final ScanArguments arguments;

  const ScanScreen({
    super.key,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final selectedType = useState(ScannerType.qr);

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.scan,
        showActionButton: false,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: selectedType.value == ScannerType.qr
                ? QrScannerScreen(arguments: arguments.qrArguments)
                : TextScannerScreen(arguments: arguments.textArguments),
          ),
          Positioned(
            top: 65,
            left: 16,
            right: 16,
            child: ToggleBar(
              onTypeChanged: (type) => selectedType.value = type,
              selectedType: selectedType.value,
            ),
          ),
        ],
      ),
    );
  }
}
