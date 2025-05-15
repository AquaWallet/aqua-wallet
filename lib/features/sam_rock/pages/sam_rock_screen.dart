import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/sam_rock/providers/sam_rock_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/subaccounts_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SamRockScreen extends HookConsumerWidget {
  const SamRockScreen({
    super.key,
    required this.samRockAppLink,
  });

  static const routeName = '/samRockScreen';

  final SamRockAppLink samRockAppLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(samRockStateProvider);
    useEffect(() {
      ref.read(subaccountsProvider.notifier).loadSubaccounts();
      return null;
    }, []);
    final subaccountsState = ref.watch(subaccountsProvider);

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'SamRock Setup',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: state.when(
          initial: () => _ConfirmationView(
            isLoading: subaccountsState.isLoading,
            uploadUrl: samRockAppLink.uploadUrl,
            onConfirm: () {
              ref
                  .read(samRockStateProvider.notifier)
                  .startSetup(samRockAppLink, subaccountsState.valueOrNull!);
            },
          ),
          loading: () => const _LoadingView(),
          error: (error) => _ErrorView(error: error),
          success: () => _SuccessView(
            setupChains: samRockAppLink.setupChains,
            otp: samRockAppLink.otp,
          ),
        ),
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({
    required this.uploadUrl,
    required this.onConfirm,
    required this.isLoading,
  });

  final String uploadUrl;
  final VoidCallback onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Uri uploadUri = Uri.parse(uploadUrl);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Confirm Host',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to send your XPUBS to:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            uploadUri.host,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.popUntilPath(AuthWrapper.routeName),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.setupChains,
    required this.otp,
  });

  final List<String> setupChains;
  final String otp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Setup of Chains',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: setupChains.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.check_circle),
                title: Text(setupChains[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.popUntilPath(AuthWrapper.routeName),
            child: const Text('Complete Setup'),
          ),
        ),
      ],
    );
  }
}
