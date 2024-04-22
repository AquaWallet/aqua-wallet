import 'package:aqua/features/shared/shared.dart';

final kBottomPadding = 48.h;
const onchainConfirmationBlockCount = 3;
const liquidConfirmationBlockCount = 2;

// this is the sideswap fee. This should ideally come from the value we
// get from the `server_status` call to sideswap. but putting this in for
// now do we are accurate in predicting how much btc/lbtc comes back to
// the user.
const sideSwapPegInOutReturnRate = .98;
