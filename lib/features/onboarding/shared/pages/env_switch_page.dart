import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/features/auth/auth_wrapper.dart';
import 'package:coin_cz/features/shared/shared.dart';

class EnvSwitchScreen extends StatelessWidget {
  const EnvSwitchScreen({super.key});

  static const routeName = '/envSwitchScreen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Consumer(builder: (context, ref, _) {
          final envType = ref.watch(envProvider);
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  ref.read(envProvider.notifier).setEnv(Env.mainnet);
                },
                child: ListTile(
                  title: const Text("Prod"),
                  leading: Radio(
                    value: Env.mainnet,
                    groupValue: envType,
                    onChanged: (envType) async {
                      ref.read(envProvider.notifier).setEnv(Env.mainnet);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(envProvider.notifier).setEnv(Env.regtest);
                },
                child: ListTile(
                  title: const Text("Regtest"),
                  leading: Radio(
                    value: Env.regtest,
                    groupValue: envType,
                    onChanged: (envType) async {
                      ref.read(envProvider.notifier).setEnv(Env.regtest);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(envProvider.notifier).setEnv(Env.testnet);
                },
                child: ListTile(
                  title: const Text("Testnet"),
                  leading: Radio(
                    value: Env.testnet,
                    groupValue: envType,
                    onChanged: (envType) async {
                      ref.read(envProvider.notifier).setEnv(Env.testnet);
                    },
                  ),
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28.0),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: AquaElevatedButton(
                  onPressed: () {
                    context.go(AuthWrapper.routeName);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
