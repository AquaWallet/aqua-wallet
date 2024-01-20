import 'package:aqua/data/models/gdk_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class GdkLoginParams {
  final GdkHwDevice? hwDevice;
  final String mnemonic;
  final String password;
  GdkLoginParams({
    this.hwDevice,
    required this.mnemonic,
    this.password = '',
  });

  GdkLoginParams copyWith({
    GdkHwDevice? hwDevice,
    String? mnemonic,
    String? password,
  }) {
    return GdkLoginParams(
      hwDevice: hwDevice ?? this.hwDevice,
      mnemonic: mnemonic ?? this.mnemonic,
      password: password ?? this.password,
    );
  }

  @override
  String toString() =>
      'GdkLoginParams(hwDevice: $hwDevice, mnemonic: $mnemonic, password: $password)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is GdkLoginParams &&
        mapEquals(other.hwDevice, hwDevice) &&
        other.mnemonic == mnemonic &&
        other.password == password;
  }

  @override
  int get hashCode => hwDevice.hashCode ^ mnemonic.hashCode ^ password.hashCode;
}
