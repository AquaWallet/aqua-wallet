String getCompressedAddress(String address) {
  const visibleCharsLength = 12;
  const lengthOfEllipsis = 3;

  const compressedAddressLength =
      visibleCharsLength + lengthOfEllipsis + visibleCharsLength;

  if (address.length > compressedAddressLength) {
    return '${address.substring(0, visibleCharsLength)}${'.' * lengthOfEllipsis}${address.substring(address.length - visibleCharsLength)}';
  }
  return address;
}
