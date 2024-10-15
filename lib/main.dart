import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_frontend/models/base_currency_model.dart';
import 'package:flutter_frontend/models/crypto_currency_model.dart';
import 'package:flutter_frontend/models/network_model.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Controller for the amount TextFormField
  final TextEditingController _amountController = TextEditingController();

  // GlobalKey for the form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // List to hold the fetched base currencies
  List<BaseCurrency> _baseCurrencies = [];

  // Variable to store the selected base currency
  BaseCurrency? _selectedBaseCurrency;

  // Variable to track loading state for base currencies
  bool _isLoading = true;

  // Variable to store base currencies error messages
  String? _errorMessage;

  // List to hold the fetched crypto currencies
  List<CryptoCurrency> _cryptoCurrencies = [];

  // Variable to store the selected crypto currency
  CryptoCurrency? _selectedCryptoCurrency;

  // List to hold networks based on selected crypto currency
  List<Network> _networks = [];

  // Variable to store the selected network
  Network? _selectedNetwork;

  // Variable to store the paymentURL
  String? paymentURL;

  @override
  void initState() {
    super.initState();
    fetchBaseCurrencies();
    fetchSupportedCryptoCurrencies();
  }

  // Generates a HMAC SHA256 signature.
  String generateHmacSignature(String dataString, String apiSecret) {
    // Convert the secret key and data string to bytes
    final List<int> key = utf8.encode(apiSecret);
    final List<int> data = utf8.encode(dataString);

    // Create a HMAC object using SHA256
    final Hmac hmacSha256 = Hmac(sha256, key); // HMAC-SHA256

    // Generate the signature as bytes
    final Digest digest = hmacSha256.convert(data);

    // Convert the signature to a hexadecimal string
    final String signature = digest.toString();

    return signature;
  }

  // Function to fetch base currencies from the API
  Future<void> fetchBaseCurrencies() async {
    final String? apiKey = dotenv.env["TLP_API_KEY"];
    final String? apiSecret = dotenv.env["TLP_API_SECRET"];
    final String apiUrl = dotenv.env["API_URL"]!;

    if (apiKey == null || apiSecret == null) {
      setState(() {
        _errorMessage = "API credentials are missing.";
        _isLoading = false;
      });
      return;
    }

    final String apiSignature = generateHmacSignature("{}", apiSecret);

    final http.Request request = http.Request(
      "GET",
      Uri.parse(
        "$apiUrl/transactions/merchant/getSupportedBaseCurrenciesList",
      ),
    );

    // Adding headers
    request.headers["X-TLP-APIKEY"] = apiKey;
    request.headers["X-TLP-SIGNATURE"] = apiSignature;

    request.bodyFields = {};

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Convert the streamed response to a string
        String responseBody = await response.stream.bytesToString();
        // Decode the JSON
        Map<String, dynamic> data = json.decode(responseBody);
        // Map the JSON to BaseCurrency objects
        setState(() {
          _baseCurrencies = (data["data"] as List<dynamic>)
              .map((item) => BaseCurrency.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.reasonPhrase ?? "Unknown error fetching base currencies";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load base currencies: $e";
        _isLoading = false;
      });
    }
  }

  // Function to fetch supported crypto currencies from the API
  Future<void> fetchSupportedCryptoCurrencies() async {
    final String? apiKey = dotenv.env["TLP_API_KEY"];
    final String? apiSecret = dotenv.env["TLP_API_SECRET"];
    final String apiUrl = dotenv.env["API_URL"]!;

    if (apiKey == null || apiSecret == null) {
      setState(() {
        _errorMessage = "API credentials are missing.";
        _isLoading = false;
      });
      return;
    }

    final String apiSignature = generateHmacSignature("{}", apiSecret);

    final http.Request request = http.Request(
      "GET",
      Uri.parse(
        "$apiUrl/transactions/merchant/getSupportedCryptoCurrenciesList",
      ),
    );

    // Adding headers
    request.headers["X-TLP-APIKEY"] = apiKey;
    request.headers["X-TLP-SIGNATURE"] = apiSignature;

    request.bodyFields = {};

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Convert the streamed response to a string
        String responseBody = await response.stream.bytesToString();
        // Decode the JSON
        Map<String, dynamic> data = json.decode(responseBody);
        // Map the JSON to CryptoCurrency objects
        setState(() {
          _cryptoCurrencies = (data["data"] as List<dynamic>)
              .map((item) => CryptoCurrency.fromJson(item))
              .toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Unknown error fetching crypto currencies";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load crypto currencies: $e";
        _isLoading = false;
      });
    }
  }

  // Function to generate payin link from the API
  Future<void> generatePayinLink({
    required String amount,
    required String baseCurrencySymbol,
    required String cryptoCurrencySymbol,
    required String networkSymbol,
  }) async {
    final String? apiKey = dotenv.env["TLP_API_KEY"];
    final String? apiSecret = dotenv.env["TLP_API_SECRET"];
    final String apiUrl = dotenv.env["API_URL"]!;

    if (apiKey == null || apiSecret == null) {
      setState(() {
        _errorMessage = "API credentials are missing.";
      });
      return;
    }

    Map<String, String> body = {
      "merchantOrderId":
          "your_order_id_${DateTime.now().millisecondsSinceEpoch}",
      "baseAmount": amount,
      "baseCurrency": baseCurrencySymbol,
      "settledCurrency": cryptoCurrencySymbol,
      "networkSymbol": networkSymbol,
      "callBackUrl": "",
      "customerName": "John Doe 1",
      "comments": "Doe Test 2"
    };

    final String apiSignature =
        generateHmacSignature(jsonEncode(body), apiSecret);

    final http.Request request = http.Request(
      "POST",
      Uri.parse(
        "$apiUrl/transactions/merchant/createPayinRequest",
      ),
    );

    // Adding headers
    request.headers["X-TLP-APIKEY"] = apiKey;
    request.headers["X-TLP-SIGNATURE"] = apiSignature;

    request.bodyFields = body;

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        // Convert the streamed response to a string
        String responseBody = await response.stream.bytesToString();
        // Decode the JSON
        Map<String, dynamic> data = json.decode(responseBody);

        setState(() {
          // Store the paymentURL
          paymentURL = data["data"]["paymentURL"];
        });
      } else {
        setState(() {
          _errorMessage = response.reasonPhrase ??
              "Unknown error, failed to create payment link";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to create payment link";
      });
    }
  }

  Future<void> _launchPaymentUrl() async {
    if (!await launchUrl(Uri.parse(paymentURL!))) {
      throw Exception('Could not launch $paymentURL');
    }
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is disposed
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tylt Flutter Example",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Tylt Flutter Example"),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 10.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Base Currency Dropdown ---
                      if (_errorMessage != null)
                        Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<BaseCurrency>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Select Base Currency",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedBaseCurrency,
                          items: _baseCurrencies
                              .map((currency) => DropdownMenuItem<BaseCurrency>(
                                    value: currency,
                                    child: Text(
                                        "${currency.currencyName} (${currency.currencySymbol})"),
                                  ))
                              .toList(),
                          onChanged: (BaseCurrency? newValue) {
                            setState(() {
                              _selectedBaseCurrency = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "Please select a currency";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- Crypto Currency Dropdown ---
                        DropdownButtonFormField<CryptoCurrency>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Select Cryptocurrency",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCryptoCurrency,
                          items: _cryptoCurrencies
                              .map(
                                (crypto) => DropdownMenuItem<CryptoCurrency>(
                                  value: crypto,
                                  child: Text(
                                      "${crypto.currencyName} (${crypto.currencySymbol})"),
                                ),
                              )
                              .toList(),
                          onChanged: (CryptoCurrency? newValue) {
                            setState(() {
                              _selectedCryptoCurrency = newValue;
                              _selectedNetwork = null;
                              _networks = newValue?.networks ?? [];
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "Please select a cryptocurrency";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- Network Dropdown (Dependent on Selected Cryptocurrency) ---
                        if (_selectedCryptoCurrency != null) ...[
                          DropdownButtonFormField<Network>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Select Network",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedNetwork,
                            items: _networks
                                .map((network) => DropdownMenuItem<Network>(
                                      value: network,
                                      child: Text(
                                          "${network.networkName} (${network.networkSymbol})"),
                                    ))
                                .toList(),
                            onChanged: (Network? newValue) {
                              setState(() {
                                _selectedNetwork = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return "Please select a network";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (_selectedBaseCurrency != null &&
                            _selectedCryptoCurrency != null &&
                            _selectedNetwork != null) ...[
                          // --- Amount TextFormField ---
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: "Amount",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter an amount";
                              }
                              final number = num.tryParse(value);
                              if (number == null) {
                                return "Please enter a valid number";
                              }
                              if (number < 0) {
                                return "Amount cannot be negative";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- Submit Button ---
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // If the form is valid, perform further actions
                              String amount = _amountController.text;
                              String baseCurrencySymbol =
                                  _selectedBaseCurrency!.currencySymbol;
                              String cryptoCurrencySymbol =
                                  _selectedCryptoCurrency!.currencySymbol;
                              String networkSymbol =
                                  _selectedNetwork!.networkSymbol;

                              generatePayinLink(
                                amount: amount,
                                baseCurrencySymbol: baseCurrencySymbol,
                                cryptoCurrencySymbol: cryptoCurrencySymbol,
                                networkSymbol: networkSymbol,
                              );

                              // For demonstration, show a dialog with all selected information
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Submission Successful"),
                                  content: Text(
                                      "Amount: $amount\nBase Currency Symbol: $baseCurrencySymbol\nCryptocurrency: $cryptoCurrencySymbol\nNetwork: $networkSymbol"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: const Text("Submit"),
                        ),
                        const SizedBox(height: 20),

                        // Payment Url
                        if (paymentURL != null)
                          ElevatedButton(
                            onPressed: _launchPaymentUrl,
                            child: const Text("Payment Link"),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
