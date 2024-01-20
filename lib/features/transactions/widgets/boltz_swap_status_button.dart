import 'dart:convert';

import 'package:aqua/common/utils/encode_query_component.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/external/boltz/boltz.dart';
import 'package:aqua/features/receive/pages/refund_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class BoltzSwapStatusButton extends ConsumerWidget {
  const BoltzSwapStatusButton({Key? key, required this.swapData})
      : super(key: key);

  final BoltzSwapData swapData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boltzRefundData =
        ref.watch(boltzSwapRefundDataProvider(swapData)).asData?.value;

    return ref.watch(boltzSwapStatusProvider(swapData.response.id)).when(
          data: (response) {
            String localizedStatus;

            if (response.status.isPending) {
              localizedStatus =
                  AppLocalizations.of(context)!.boltzSendStatusPending;
            } else if (response.status.isFailed) {
              localizedStatus =
                  AppLocalizations.of(context)!.boltzSendStatusFailed;
            } else if (response.status.isSuccess) {
              localizedStatus =
                  AppLocalizations.of(context)!.boltzSendStatusSuccess;
            } else {
              localizedStatus =
                  AppLocalizations.of(context)!.boltzSendUnknownStatus;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //ANCHOR - Status
                Text(
                  localizedStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: response.status.isFailed
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),

                //ANCHOR - Refund button
                if (response.status.isFailed) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      final address =
                          await ref.read(liquidProvider).getReceiveAddress();
                      final jsonString = jsonEncode(boltzRefundData!.toJson());

                      if (address != null && context.mounted) {
                        Navigator.of(context).pushNamed(RefundScreen.routeName,
                            arguments:
                                RefundArguments(address.address!, jsonString));
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.boltzRefund),
                  ),
                ],

                //HERE: Refund Data
                //ANCHOR - Copy Refund Data
                if (!response.status.isSuccess) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      final jsonString = jsonEncode(boltzRefundData!.toJson());
                      context.copyToClipboard(jsonString);
                    },
                    child:
                        Text(AppLocalizations.of(context)!.boltzCopyRefundData),
                  ),
                ],

                //ANCHOR - Boltz Support
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    launchUrl(Uri(
                      scheme: 'mailto',
                      path: boltzSupportEmail,
                      query: encodeQueryParameters(<String, String>{
                        'subject':
                            'Aqua - Boltz Swap Id: ${swapData.response.id}',
                        'cc': aquaSupportEmail,
                      }),
                    ));
                  },
                  child: Text(AppLocalizations.of(context)!.boltzSupportEmail),
                ),
              ],
            );
          },
          loading: () => Container(),
          error: (e, st) {
            logger.d("[BOLTZ] Error retrieving swap status: $e");
            return Text(
              AppLocalizations.of(context)!.boltzSendUnknownStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            );
          },
        ); // Error widget
  }
}
