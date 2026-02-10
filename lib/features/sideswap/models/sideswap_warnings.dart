abstract class SideswapWarning {
  SideswapWarning({required this.message});

  final String message;

  @override
  String toString() => message;
}

class SideswapSendAllFeeWarning extends SideswapWarning {
  SideswapSendAllFeeWarning({required super.message});

  @override
  String toString() => message;
}

class SideswapInsufficientLiquidityWarning extends SideswapWarning {
  SideswapInsufficientLiquidityWarning({required super.message});

  @override
  String toString() => message;
}
