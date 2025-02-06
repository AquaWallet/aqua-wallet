import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

class DecimalConverter implements JsonConverter<Decimal, String> {
  const DecimalConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  @override
  String toJson(Decimal decimal) => decimal.toString();
}
