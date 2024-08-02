import 'package:dio/dio.dart';

class BitcoinUSDPrice {
  final Dio _client;

  BitcoinUSDPrice(this._client);

  Future<double> fetchPrice() async {
    const String uri = 'https://api.kraken.com/0/public/Ticker?pair=XBTUSD';

    try {
      final response = await _client.get(uri);
      final data = response.data;
      final result = data['result']['XXBTZUSD'];
      final price = double.parse(result['a'][0]); // `['a'][0]` is the ask price
      return price;
    } on DioException catch (e) {
      throw Exception('Failed to fetch Bitcoin USD price: ${e.message}');
    }
  }
}
