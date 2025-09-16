import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class AddressSelectionScreen extends ConsumerWidget {
  static const routeName = '/addressSelectionScreen';

  final List<String> addresses;

  const AddressSelectionScreen({
    super.key,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.selectAddress,
        showBackButton: true,
        showActionButton: false,
      ),
      body: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: addresses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14.0),
          itemBuilder: (ctx, index) {
            final address = addresses[index];
            return _AddressTile(
              address: address,
              onTap: () => Navigator.of(context).pop(address),
            );
          }),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.onTap,
  });

  bool _isAmbiguousChar(String char) {
    // Shound be added more
    return [
      'o',
      'i',
      'l',
    ].contains(char);
  }

  bool _isDigit(String char) {
    return ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(char);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(children: _buildTextSpans(context)),
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                Svgs.chevronRight,
                width: 15.0,
                height: 15.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final defaultStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    return address.split('').map((char) {
      final color = _isAmbiguousChar(char)
          ? context.colors.redAmbiguousChars
          : _isDigit(char)
              ? context.colorScheme.primary
              : null;
      return TextSpan(
        text: char,
        style: color != null
            ? defaultStyle?.copyWith(
                color: color,
              )
            : defaultStyle,
      );
    }).toList();
  }
}
