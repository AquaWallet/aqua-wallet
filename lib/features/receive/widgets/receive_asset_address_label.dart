import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAssetAddressLabel extends HookWidget {
  const ReceiveAssetAddressLabel({
    super.key,
    required this.assetName,
  });

  final String assetName;

  @override
  Widget build(BuildContext context) {
    final chunks = useMemoized(() {
      final text = AppLocalizations.of(context)!
          .receiveAssetScreenDescription(assetName);
      return text.split(RegExp('(?<=$assetName)|(?=$assetName)'));
    });

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      child: Text.rich(
        TextSpan(
          children: chunks.map((text) {
            return TextSpan(
              text: text,
              style: text == assetName
                  ? Theme.of(context).richTextStyleBold
                  : Theme.of(context).richTextStyleNormal,
            );
          }).toList(),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
