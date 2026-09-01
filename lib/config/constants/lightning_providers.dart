// Lightning swap providers. Boltz served every swap until it shut down, so its
// API hosts are frozen. History names a swap from the API URL stored with it,
// and swaps with no URL are old enough that Boltz is the only provider they can
// have used.
const legacyLnProviderName = 'Boltz';
const legacyLnProviderWebsite = 'https://boltz.exchange';
const legacyLnProviderApiHost = 'boltz.exchange';

// Provider serving swaps now. Ankara names it in the setup config
// (`submarine-ln-provider-name` / `reverse-ln-provider-name` under
// `base_urls`), so this constant is only the fallback for a config we have
// not fetched or one that omits the name keys.
const currentLnProviderName = 'Indra';

/// API hosts of providers that no longer serve swaps. A retired host never
/// changes, so a swap that used one keeps its provider name however often the
/// current provider changes. Add an entry when a provider retires — never for
/// the current one, which [lnProviderNameForApiUrl] names by default.
const _retiredLnProviderHosts = {
  legacyLnProviderApiHost: legacyLnProviderName,
};

/// Provider that served a swap, read from the API URL stored with it.
///
/// A swap without a stored URL is a v0 record, and v0 predates every provider
/// except Boltz. A URL that is not a retired host belongs to the current
/// provider, whose name Ankara configures — pass it as [currentName] where a
/// setup config is available.
String lnProviderNameForApiUrl(
  String? apiUrl, {
  String currentName = currentLnProviderName,
}) {
  if (apiUrl == null || apiUrl.isEmpty) {
    return legacyLnProviderName;
  }
  final host = Uri.tryParse(apiUrl)?.host;
  for (final entry in _retiredLnProviderHosts.entries) {
    // Match a parsed host exactly, or as a subdomain, so a retired name in a
    // path cannot mislabel a current-provider swap. A value with no parseable
    // host is plain text, not a host, so search it for the name instead.
    final matches = (host == null || host.isEmpty)
        ? apiUrl.contains(entry.key)
        : host == entry.key || host.endsWith('.${entry.key}');
    if (matches) {
      return entry.value;
    }
  }
  return currentName;
}
