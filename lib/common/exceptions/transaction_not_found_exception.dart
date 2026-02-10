import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

class SelectionUnavailableException implements ExceptionLocalized {
  const SelectionUnavailableException();

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.selectionUnavailable;
  }
}
