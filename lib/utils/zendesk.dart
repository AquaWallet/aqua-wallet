import 'package:aqua/config/constants/constants.dart';

String buildUrlWithParams(
  String baseUrl, {
  Map<String, String>? queryParams,
}) {
  if (queryParams == null || queryParams.isEmpty) {
    return baseUrl;
  }

  final uri = Uri.parse(baseUrl);
  final existingParams = Map<String, String>.from(uri.queryParameters);

  for (final entry in queryParams.entries) {
    if (entry.value.isNotEmpty) {
      existingParams[entry.key] = entry.value;
    }
  }

  return uri.replace(queryParameters: existingParams).toString();
}

String getAquaZendeskUrl(String aquaVersion) {
  return buildUrlWithParams(
    aquaZendeskUrl,
    queryParams: {
      'tf_$zendeskFormFieldAquaVersion': aquaVersion,
    },
  );
}

String getAquaMoonZendeskUrl(
    String subject, String cardId, String aquaVersion) {
  return buildUrlWithParams(
    aquaZendeskMoonUrl,
    queryParams: {
      'tf_$zendeskFormFieldCardFieldId': cardId,
      'tf_$zendeskFormFieldAquaVersion': aquaVersion,
      'tf_subject': subject,
    },
  );
}
