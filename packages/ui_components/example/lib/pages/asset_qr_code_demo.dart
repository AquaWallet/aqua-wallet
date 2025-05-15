import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

const _qrCodeBitcoin = 'bc1qnh27hg7yy2m8jpmzy6t77sj3pk52u05n2ju8cs';
const _qrCodeLbtc =
    'VJLEERnmhwXPBP9BEH9xUfg7TYxDiXaZavjydBptPDqQiEUZvipYmggVcJdL8qUKqpy91wxUxZiGruR2';
const _qrCodeLn =
    'lnbc10u1pn7l5s8sp5wwzy3m5w26q3flj9xdxaakxmj0mqvq7sznml46ga7gyma7ucnj2spp5lfl7gdf7ucf4f8c22jwmrmd32k3ytevp73dg6czvl9fr5dkayqcqdpz2djkuepqw3hjqnpdgf2yxgrpv3j8yetnwvxqyp2xqcqz95rzjqg6jlc8vcxzf5ctp7e90qhccl6cyh3dl6ga5hqahwnzmq2svmat0qzzxeyqq28qqqqqqqqqqqqqqq9gq2y9qyysgqdd5thfunvacc5ed9w6zxdvg8rxvcvt9fhmv4ltwwn8z758cfsj64n9uksud5auk8cundkmt3yecg7qyjnfk4dwjah80krqafutqh5ecpgkeupe';
const _qrCodeUsdt =
    'VJLB6vX76Q5UmTkSF6Qy8C59SYRsJocEe2MaVvD4boAydjf9jnKTWCC93AeuKhiccX2gkDF5WuPPJuRx';
const _qrCodeEth = '0xD0285a0Cc29f2F31d3A98Dd2eA991B39dB4Bc076';
const _qrCodeTron = 'TV1Cu66tKAJVKoMxRBockuDbNBMPawxS31';
const _qrCodeBnb = '0xa3537f394819fa38788c81e17baf9fed8364ff79';
const _qrCodeSol = 'EHa3te7FbJxfFBEPMQizr8dwpWqi1ACqMnHxfmzHBoUe';
const _qrCodePol = '0xb0EA2f0904d71A000E063001603ceC39Ae4A9EbC';
const _qrCodeTon = 'EQD5mxRgCuRNLxKxeOjG6r14iSroLF5FtomPnet-sgP5xNJb';
const _qrCodeDepix =
    'VJL7bKERpNU3BPEYW2bP8iUWooSEQDdG1DT1NEUPDe3ruhnUPKM8FyoE17565ZYABtW5SFy9RAKSzteY';

class AssetQRCodeDemoPage extends HookConsumerWidget {
  const AssetQRCodeDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const AquaAssetQRCode(
            content: _qrCodeDepix,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeBitcoin,
            assetId: AssetIds.btc,
          ),
          const SizedBox(width: 60),
          AquaAssetQRCode(
            content: _qrCodeLbtc,
            assetId: AssetIds.lbtc.first,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeLn,
            assetId: AssetIds.lightning,
          ),
          const SizedBox(width: 60),
          AquaAssetQRCode(
            content: _qrCodeUsdt,
            assetId: AssetIds.usdtliquid.first,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeEth,
            assetId: AssetIds.usdtEth,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeTron,
            assetId: AssetIds.usdtTrx,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeBnb,
            assetId: AssetIds.usdtBep,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeSol,
            assetId: AssetIds.usdtSol,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodePol,
            assetId: AssetIds.usdtPol,
          ),
          const SizedBox(width: 60),
          const AquaAssetQRCode(
            content: _qrCodeTon,
            assetId: AssetIds.usdtTon,
          ),
        ],
      ),
    );
  }
}
