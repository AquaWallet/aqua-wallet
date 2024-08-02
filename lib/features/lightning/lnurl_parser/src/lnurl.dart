/// Parse and return a given lnurl string if it's valid. Will remove
/// `lightning:` from the beginning of it if present.
String findLnUrl(String input) {
  final res = RegExp(
    r',*?((lnurl)([0-9]{1,}[a-z0-9]+){1})',
  ).allMatches(input.toLowerCase());

  if (res.length == 1) {
    return res.first.group(0)!;
  } else {
    throw ArgumentError('Not a valid lnurl string');
  }
}
