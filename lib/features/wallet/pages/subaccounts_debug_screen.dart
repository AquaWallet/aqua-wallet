import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/config/theme/app_styles.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/features/wallet/providers/current_shared_subaccount_provider.dart';
import 'package:aqua/features/wallet/providers/liquid_native_segwit_sweep_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/features/wallet/providers/subaccounts_provider.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';

//TODO: Block "Create Subaccount" button if not yet swept to native segwit
class SubaccountsDebugScreen extends HookConsumerWidget {
  const SubaccountsDebugScreen({super.key});

  static const routeName = '/subaccountsDebugScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subaccountsState = ref.watch(subaccountsProvider);
    final sweepState = ref.watch(liquidNativeSegwitSweepProvider);

    final subaccountsError = useMemoized(() {
      if (subaccountsState is AsyncError) {
        final error = (subaccountsState.error as ExceptionLocalized)
            .toLocalizedString(context);
        return error;
      }
      return null;
    }, [subaccountsState, context]);

    final sweepError = useMemoized(() {
      if (sweepState is AsyncError) {
        final error =
            (sweepState.error as ExceptionLocalized).toLocalizedString(context);
        return error;
      }
      return null;
    }, [sweepState, context]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(subaccountsProvider.notifier).loadSubaccounts();
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: 'Subaccounts',
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: Column(
        children: [
          CustomError(errorMessage: subaccountsError),
          CustomError(errorMessage: sweepError),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(subaccountsProvider.notifier)
                        .createNativeSegwitLiquidSubaccount();
                  },
                  child: const Text('Create Native Segwit Liquid Subaccount'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showSweepWarning(context, ref);
                  },
                  child:
                      const Text('Sweep Legacy Segwit Liquid to Native Segwit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: subaccountsState.when(
              data: (subaccounts) {
                return ListView.builder(
                  itemCount: subaccounts.subaccounts.length,
                  itemBuilder: (context, index) {
                    final subaccount = subaccounts.subaccounts[index];
                    return SubaccountListItem(
                      subaccount: subaccount,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(), // Error handled above
            ),
          ),
        ],
      ),
    );
  }

  void _showSweepWarning(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'Warning! Use with *TESTNET* only until fully tested. '
            'This will sweep all your Liquid funds from the Legacy Segwit account '
            'we\'ve been using to a new Native Segwit account!',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                context.pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                ref
                    .read(liquidNativeSegwitSweepProvider.notifier)
                    .sweepLegacyToNativeSegwit();
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }
}

class SubaccountListItem extends HookConsumerWidget {
  final Subaccount subaccount;

  const SubaccountListItem({
    super.key,
    required this.subaccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subaccountsNotifier = ref.watch(subaccountsProvider.notifier);
    final nameController =
        useTextEditingController(text: subaccount.subaccount.name ?? '');
    final isNameEdited = useState(false);

    useEffect(() {
      void listener() {
        isNameEdited.value =
            nameController.text.trim() != (subaccount.subaccount.name ?? '');
      }

      nameController.addListener(listener);
      return () => nameController.removeListener(listener);
    }, [nameController, subaccount.subaccount.name]);

    final updateSubaccountName = useCallback(() async {
      final newName = nameController.text.trim();
      if (newName.isNotEmpty && newName != subaccount.subaccount.name) {
        final updateDetails = GdkSubaccountUpdate(
          subaccount: subaccount.subaccount.pointer!,
          name: newName,
        );

        try {
          await ref.read(subaccountsProvider.notifier).updateSubaccount(
                updateDetails,
                subaccount.networkType,
              );
          isNameEdited.value = false;
        } catch (e) {
          if (e is ExceptionLocalized && context.mounted) {
            final errorMessage = e.toLocalizedString(context);
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(errorMessage),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    }, [nameController, subaccount, ref, isNameEdited, context]);

    //  if (ref.read(featureFlagsProvider).throwAquaBroadcastErrorEnabled) {
    //       throw AquaTxBroadcastException();
    //     }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(subaccount.subaccount.name ?? 'Unnamed Subaccount'),
        subtitle: FutureBuilder<int>(
          future: subaccountsNotifier.getSubaccountTransactionCount(
            Subaccount(
              subaccount: subaccount.subaccount,
              networkType: subaccount.networkType,
            ),
          ),
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Path: ${DerivationPathUtils.formatDerivationPath(subaccount.subaccount.userPath)} (${subaccount.networkType.name})'),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Text('Transactions: Loading...'),
                if (snapshot.hasError)
                  Text('Transactions: Error (${snapshot.error})'),
                if (snapshot.hasData)
                  Text(
                      'Transactions: ${snapshot.data! >= 30 ? '30+' : snapshot.data}'),
              ],
            );
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Subaccount Name',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed:
                          isNameEdited.value ? updateSubaccountName : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final gdkSubaccount = subaccount.subaccount;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                            'Type', gdkSubaccount.type?.toString() ?? 'N/A'),
                        _buildDetailRow(
                            'Type Name', gdkSubaccount.type?.typeName ?? 'N/A'),
                        _buildDetailRow('Pointer',
                            gdkSubaccount.pointer?.toString() ?? 'N/A'),
                        _buildDetailRow(
                            'Receiving ID', gdkSubaccount.receivingId ?? 'N/A'),
                        _buildDetailRow('Required CA',
                            gdkSubaccount.requiredCa?.toString() ?? 'N/A'),
                        _buildDetailRow(
                            'Hidden', gdkSubaccount.hidden.toString()),
                        _buildDetailRow('BIP44 Discovered',
                            gdkSubaccount.bip44Discovered.toString()),
                        if (gdkSubaccount.coreDescriptors != null &&
                            gdkSubaccount.coreDescriptors!.isNotEmpty)
                          _buildDetailRow('Core Descriptors',
                              gdkSubaccount.coreDescriptors!.join(', ')),
                        if (gdkSubaccount.slip132ExtendedPubkey != null)
                          _buildDetailRow('SLIP132 Extended Pubkey',
                              gdkSubaccount.slip132ExtendedPubkey!),
                        if (gdkSubaccount.userPath != null &&
                            gdkSubaccount.userPath!.isNotEmpty)
                          _buildDetailRow(
                              'User Path', gdkSubaccount.userPath!.join('/')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(currentSharedSubaccountProvider.notifier)
                                .setCurrentSharedSubaccount(subaccount);
                          },
                          child: const Text('Set Active'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
