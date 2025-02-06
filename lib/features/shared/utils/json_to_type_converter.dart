import 'dart:convert';

import 'package:chopper/chopper.dart';

class JsonToTypeConverter extends JsonConverter {
  final Map<Type, Function> typeToJsonFactoryMap;

  const JsonToTypeConverter(this.typeToJsonFactoryMap);

  @override
  Response<BodyType> convertResponse<BodyType, InnerType>(Response response) {
    return response.copyWith(
      body: fromJsonData<BodyType, InnerType>(
        response.body,
        typeToJsonFactoryMap[InnerType]!,
      ),
    );
  }

  T fromJsonData<T, InnerType>(String jsonData, Function jsonParser) {
    final jsonMap = jsonDecode(jsonData);

    if (jsonMap is List) {
      return jsonMap
          .map((item) => jsonParser(item as Map<String, dynamic>) as InnerType)
          .toList() as T;
    }

    return jsonParser(jsonMap);
  }
}
