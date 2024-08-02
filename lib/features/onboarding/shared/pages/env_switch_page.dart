import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/shared/shared.dart';

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
                margin: EdgeInsets.symmetric(horizontal: 28.w),
                padding: EdgeInsets.only(bottom: 16.h),
                child: AquaElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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
