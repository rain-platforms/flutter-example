class BaseCurrency {
  final String currencyName;
  final String currencySymbol;

  BaseCurrency({required this.currencyName, required this.currencySymbol});

  factory BaseCurrency.fromJson(Map<String, dynamic> json) {
    return BaseCurrency(
      currencyName: json['currencyName'],
      currencySymbol: json['currencySymbol'],
    );
  }
}
