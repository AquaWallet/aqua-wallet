class BlockExplorer {
  final String name;
  final String btcUrl;
  final String liquidUrl;

  static const List<BlockExplorer> availableBlockExplorers = [
    BlockExplorer(
      name: "blockstream.info",
      btcUrl: 'https://blockstream.info/tx/',
      liquidUrl: 'https://blockstream.info/liquid/tx/',
    ),
    BlockExplorer(
      name: "mempool.space",
      btcUrl: 'https://mempool.space/tx/',
      liquidUrl: 'https://liquid.network/tx/',
    ),
  ];

  const BlockExplorer({
    required this.name,
    required this.btcUrl,
    required this.liquidUrl,
  });
}
