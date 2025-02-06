import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';

const kBitcoinUrl = 'bitcoinUrl';
const kLiquidUrl = 'liquidUrl';
const kWebsiteUrlPattern =
    r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&/=]*)$';

class ElectrumServerSettingsScreen extends HookConsumerWidget {
  static const routeName = '/electrumServerSettingsScreen';

  const ElectrumServerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomElectrumServer = ref.watch(
      electrumServerProvider.select((p) => p.isCustomElectrumServer),
    );
    final currentBitcoinUrl = ref.watch(
      electrumServerProvider.select((p) => p.customElectrumServerBtcUrl),
    );
    final currentLiquidUrl = ref.watch(
      electrumServerProvider.select((p) => p.customElectrumServerLiquidUrl),
    );
    final options = useMemoized(() {
      final items = [
        context.loc.defaultElectrumServer,
        context.loc.personalElectrumServer,
      ];
      return items
          .mapIndexed((index, item) => SettingsItem.create(
                index == 1,
                name: item,
                index: index,
                length: items.length,
              ))
          .toList();
    });

    final showCustomUrlInputSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        builder: (_) => _CustomBlockExplorerUrlSheet(
          onConfirm: ref.read(electrumServerProvider).setElectrumServer,
          customBlockExplorerBitcoinUrl: currentBitcoinUrl,
          customBlockExplorerLiquidUrl: currentLiquidUrl,
        ),
      );
    }, [isCustomElectrumServer]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.electrumServer,
        backgroundColor: context.colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: isCustomElectrumServer
              ? context.loc.custom
              : context.loc.defaultElectrumServer,
          items: options,
          itemBuilder: (context, item) {
            final isCustom = item.object as bool;
            return SettingsListSelectionItem(
              content: Text(item.name),
              position: item.position,
              onPressed: isCustom
                  ? showCustomUrlInputSheet
                  : ref
                      .read(electrumServerProvider)
                      .setDefaultElectrumServerUrls,
            );
          },
        ),
      ),
    );
  }
}

class _CustomBlockExplorerUrlSheet extends HookWidget {
  const _CustomBlockExplorerUrlSheet({
    required this.onConfirm,
    required this.customBlockExplorerBitcoinUrl,
    required this.customBlockExplorerLiquidUrl,
  });

  final String customBlockExplorerBitcoinUrl;
  final String customBlockExplorerLiquidUrl;
  final Function(ElectrumConfig config) onConfirm;

  @override
  Widget build(BuildContext context) {
    final bitcoinUrlController = useTextEditingController(
      text: customBlockExplorerBitcoinUrl,
    );
    final liquidUrlController = useTextEditingController(
      text: customBlockExplorerLiquidUrl,
    );
    final bitcoinControllerText = useValueListenable(bitcoinUrlController);
    final bitcoinClearButtonOpacity = useMemoized(
      () => bitcoinUrlController.text.isNotEmpty ? 1.0 : 0.0,
      [bitcoinControllerText],
    );
    final liquidControllerText = useValueListenable(liquidUrlController);
    final liquidClearButtonOpacity = useMemoized(
      () => liquidUrlController.text.isNotEmpty ? 1.0 : 0.0,
      [liquidControllerText],
    );
    final formGroup = useMemoized(
      () => FormGroup({
        kBitcoinUrl: FormControl<String>(
          value: bitcoinUrlController.text,
          validators: [
            Validators.required,
            Validators.pattern(kWebsiteUrlPattern),
          ],
        ),
        kLiquidUrl: FormControl<String>(
          value: liquidUrlController.text,
          validators: [
            Validators.required,
            Validators.pattern(kWebsiteUrlPattern),
          ],
        ),
      }),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReactiveForm(
          formGroup: formGroup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              //ANCHOR - Title
              Center(
                child: Text(
                  context.loc.customElectrumServer,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              //ANCHOR - Description
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  context.loc.pleaseChooseTheElectrumServersYouTrust,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    letterSpacing: 0.5,
                    wordSpacing: 2,
                    fontFamily: UiFontFamily.inter,
                    fontWeight: FontWeight.w400,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              //ANCHOR - Bitcoin URL Input
              Text(
                context.loc.bitcoinUrl,
                style: TextStyle(
                  color: context.colors.onBackground,
                  fontSize: 14,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                controller: bitcoinUrlController,
                formControlName: kBitcoinUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: Theme.of(context).outlineInputDecoration.copyWith(
                      hintText: context.loc.domainCom,
                      suffixIcon: _ClearInputButton(
                        onTap: () {
                          bitcoinUrlController.clear();
                          formGroup.control(kBitcoinUrl).reset();
                        },
                        opacity: bitcoinClearButtonOpacity,
                      ),
                    ),
                validationMessages: {
                  'required': (error) =>
                      context.loc.bitcoinElectrumServerUrlRequired,
                  'pattern': (error) => context.loc.pleaseEnterAValidUrl,
                },
              ),
              const SizedBox(height: 8),
              //ANCHOR - Liquid URL Input
              Text(
                context.loc.liquidUrl,
                style: TextStyle(
                  color: context.colors.onBackground,
                  fontSize: 14,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                controller: liquidUrlController,
                formControlName: kLiquidUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: Theme.of(context).outlineInputDecoration.copyWith(
                      hintText: context.loc.domainCom,
                      suffixIcon: _ClearInputButton(
                        onTap: () {
                          liquidUrlController.clear();
                          formGroup.control(kLiquidUrl).reset();
                        },
                        opacity: liquidClearButtonOpacity,
                      ),
                    ),
                validationMessages: {
                  'required': (_) =>
                      context.loc.liquidElectrumServerUrlRequired,
                  'pattern': (_) => context.loc.pleaseEnterAValidUrl,
                },
              ),
              const SizedBox(height: 12),
              //ANCHOR - Warning Text
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(4),
                      child: UiAssets.info.svg(
                        width: 24,
                        height: 24,
                        color: AquaColors.brightPastelOrange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.loc.electrumServerWarning,
                        style: const TextStyle(
                          fontSize: 12,
                          wordSpacing: 1.5,
                          color: AquaColors.brightPastelOrange,
                          fontFamily: UiFontFamily.inter,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              //ANCHOR - Confirm Button
              ReactiveFormConsumer(
                builder: (context, form, child) => AquaElevatedButton(
                  onPressed: form.valid
                      ? () {
                          onConfirm(ElectrumConfig(
                            btcUrl: form.value[kBitcoinUrl]?.toString() ?? '',
                            liquidUrl: form.value[kLiquidUrl]?.toString() ?? '',
                          ));
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(context.loc.confirm),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearInputButton extends StatelessWidget {
  const _ClearInputButton({
    required this.onTap,
    required this.opacity,
  });

  final VoidCallback onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(right: 24),
        child: Center(
          child: ClearInputButton(
            onTap: opacity > 0 ? onTap : null,
          ),
        ),
      ),
    );
  }
}
