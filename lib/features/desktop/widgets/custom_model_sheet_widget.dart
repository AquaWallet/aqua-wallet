import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class CustomModelSheetWidget extends HookWidget {
  const CustomModelSheetWidget({
    required this.aquaColors,
    required this.loc,
    super.key,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.sizeOf(context).height / screenParts,
      ),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 20,
          left: context.isSmallMobile || context.isMobile ? 16 : 0,
          right: context.isSmallMobile || context.isMobile ? 16 : 0,
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: aquaColors.surfacePrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: aquaColors.systemBackgroundColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 32),
                AquaText.h4Medium(
                  text: 'Add Note',
                  size: 24,
                  color: aquaColors.textPrimary,
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 32,
                    top: 24,
                  ),
                  child: AquaTextField(
                    controller: textController,
                    maxLines: 5,
                    minLines: 3,
                    maxLength: 200,
                    label: 'Add note',
                    showCounter: true,
                  ),
                ),
                AquaButton.primary(
                  text: loc.save,
                  onPressed: () {
                    Navigator.pop(context, textController.text);
                  },
                ),
                const SizedBox(height: 16),
                AquaButton.secondary(
                  text: loc.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
