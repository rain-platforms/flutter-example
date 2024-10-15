import 'package:flutter_frontend/models/network_model.dart';

class CryptoCurrency {
  final String currencyName;
  final String currencySymbol;
  final List<Network> networks;

  CryptoCurrency({
    required this.currencyName,
    required this.currencySymbol,
    required this.networks,
  });

  factory CryptoCurrency.fromJson(Map<String, dynamic> json) {
    var networksFromJson = json['networks'] as List<dynamic>;
    List<Network> networkList =
        networksFromJson.map((net) => Network.fromJson(net)).toList();

    return CryptoCurrency(
      currencyName: json['currencyName'],
      currencySymbol: json['currencySymbol'],
      networks: networkList,
    );
  }
}
