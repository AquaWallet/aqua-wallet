abstract class SideswapException {
  SideswapException({required this.message});

  final String message;

  bool get isDeliverException =>
      this is SideswapSendAmountException ||
      (this is SideswapInsufficientFundsException &&
          (this as SideswapInsufficientFundsException).isDeliver);
  bool get isReceiveException =>
      this is SideswapReceiveAmountException ||
      this is SideswapInvalidArgumentsException ||
      (this is SideswapInsufficientFundsException &&
          !(this as SideswapInsufficientFundsException).isDeliver);

  @override
  String toString() => message;
}

class SideswapInvalidArgumentsException extends SideswapException {
  SideswapInvalidArgumentsException({required super.message});

  @override
  String toString() => message;
}

class SideswapInsufficientFundsException extends SideswapException {
  SideswapInsufficientFundsException({
    required this.isDeliver,
    required super.message,
  });

  final bool isDeliver;

  @override
  String toString() => message;
}

class SideswapSendAmountException extends SideswapException {
  SideswapSendAmountException({required super.message});

  @override
  String toString() => message;
}

class SideswapReceiveAmountException extends SideswapException {
  SideswapReceiveAmountException({required super.message});

  @override
  String toString() => message;
}

class SideswapMinPegInAmountException extends SideswapException {
  SideswapMinPegInAmountException({required super.message});

  @override
  String toString() => message;
}

class SideswapMinPegOutAmountException extends SideswapException {
  SideswapMinPegOutAmountException({required super.message});

  @override
  String toString() => message;
}
