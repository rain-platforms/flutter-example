class Network {
  final String standard;
  final bool canDeposit;
  final bool canWithdraw;
  final double networkFees;
  final String networkName;
  final String networkSymbol;
  final double maximumDeposit;
  final double minimumDeposit;
  final String contractAddress;
  final double maximumWithdrawal;
  final double minimumWithdrawal;

  Network({
    required this.standard,
    required this.canDeposit,
    required this.canWithdraw,
    required this.networkFees,
    required this.networkName,
    required this.networkSymbol,
    required this.maximumDeposit,
    required this.minimumDeposit,
    required this.contractAddress,
    required this.maximumWithdrawal,
    required this.minimumWithdrawal,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      standard: json['standard'] ?? '',
      canDeposit: json['canDeposit'] == 1,
      canWithdraw: json['canWithdraw'] == 1,
      networkFees: (json['networkFees'] as num).toDouble(),
      networkName: json['networkName'],
      networkSymbol: json['networkSymbol'],
      maximumDeposit: (json['maximumDeposit'] as num).toDouble(),
      minimumDeposit: (json['minimumDeposit'] as num).toDouble(),
      contractAddress: json['contractAddress'],
      maximumWithdrawal: (json['maximumWithdrawal'] as num).toDouble(),
      minimumWithdrawal: (json['minimumWithdrawal'] as num).toDouble(),
    );
  }
}
