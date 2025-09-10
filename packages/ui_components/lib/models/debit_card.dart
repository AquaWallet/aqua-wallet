import 'package:ui_components/gen/assets.gen.dart';

@JsonEnum()
enum CardStyle {
  style1,
  style2,
  style3,
  style4,
  style5,
  style6,
  style7,
  style8,
  style9,
  style10,
}

CardStyle cardStyleFromString(String? style) => CardStyle.values.firstWhere(
  (e) => e.toString() == 'CardStyle.$style',
  orElse: () => CardStyle.style1,
);

extension CardStyleExtension on CardStyle {
  AssetGenImage get frontImage => switch (this) {
    CardStyle.style2 => AquaUiAssets.images.card2Front,
    CardStyle.style3 => AquaUiAssets.images.card3Front,
    CardStyle.style4 => AquaUiAssets.images.card4Front,
    CardStyle.style5 => AquaUiAssets.images.card5Front,
    CardStyle.style6 => AquaUiAssets.images.card6Front,
    CardStyle.style7 => AquaUiAssets.images.card7Front,
    CardStyle.style8 => AquaUiAssets.images.card8Front,
    CardStyle.style9 => AquaUiAssets.images.card9Front,
    CardStyle.style10 => AquaUiAssets.images.card10Front,
    _ => AquaUiAssets.images.card1Front,
  };

  AssetGenImage get backImage => switch (this) {
    CardStyle.style7 || CardStyle.style8 => AquaUiAssets.images.card2Back,
    CardStyle.style5 || CardStyle.style6 => AquaUiAssets.images.card3Back,
    CardStyle.style9 || CardStyle.style10 => AquaUiAssets.images.card4Back,
    _ => AquaUiAssets.images.card1Back,
  };
}
