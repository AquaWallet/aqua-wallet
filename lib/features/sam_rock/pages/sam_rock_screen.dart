import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/provider/app_links/app_link.dart';
import 'package:coin_cz/features/auth/auth_wrapper.dart';
import 'package:coin_cz/features/sam_rock/models/sam_rock_exception.dart';
import 'package:coin_cz/features/sam_rock/providers/sam_rock_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/providers/subaccounts_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:coin_cz/utils/utils.dart';

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

    final handleConfirm = useCallback(() {
      final currentSubaccounts = subaccountsState.valueOrNull;
      if (currentSubaccounts != null) {
        ref.read(samRockStateProvider.notifier).startSetup(
              samRockAppLink,
              currentSubaccounts,
            );
      }
    }, [ref, samRockAppLink, subaccountsState]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.samRockScreenAppBarTitle,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: state.maybeWhen(
          requiresNewWalletConfirmation: (_) => _ConfirmationView(
            isLoading: subaccountsState.isLoading,
            uploadUrl: samRockAppLink.uploadUrl,
            onConfirm: handleConfirm,
          ),
          initial: () => _ConfirmationView(
            isLoading: subaccountsState.isLoading,
            uploadUrl: samRockAppLink.uploadUrl,
            onConfirm: handleConfirm,
          ),
          loading: () => const _LoadingView(),
          error: (error) => _ErrorView(exception: error),
          success: () => _SuccessView(
            setupChains: samRockAppLink.setupChains,
            otp: samRockAppLink.otp,
          ),
          orElse: () => const Center(child: CircularProgressIndicator()),
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
            context.loc.samRockScreenConfirmHostTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            context.loc.samRockScreenConfirmHostSubtitle,
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
                child: Text(context.loc.cancel),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(context.loc.confirm),
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
  const _ErrorView({required this.exception});

  final SamRockException exception;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.loc.error,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(exception.toLocalizedString(context)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.popUntilPath(AuthWrapper.routeName),
            child: Text(context.loc.goBack),
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
          context.loc.samRockScreenSuccessTitle,
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
            child: Text(context.loc.samRockScreenCompleteSetupButton),
          ),
        ),
      ],
    );
  }
}
