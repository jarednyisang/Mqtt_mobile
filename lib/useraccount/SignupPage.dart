import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:surveyhub/utils/AppColors.dart';
import 'package:surveyhub/utils/BaseUrl.dart';
import 'package:surveyhub/utils/SplashScreen.dart';


// Add the CountriesModel class
class CountriesModel {
  final int id;
  final String countryName;

  CountriesModel({
    required this.id,
    required this.countryName,
  });

  factory CountriesModel.fromJson(Map<String, dynamic> json) {
    return CountriesModel(
      id: json['id'],
      countryName: json['country_name'] ?? json['country'], // Handle both field names
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '', refcode = '', email = '', password = '', passwordConfirmation = '';
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  bool _agreeTerms = false;

  // Country dropdown variables
  List<CountriesModel> _countries = [];
  List<CountriesModel> _filteredCountries = [];
  int? _selectedCountryId;
  bool _isLoadingCountries = false;
  String _countryErrorMessage = '';
  
  // Search functionality
  final TextEditingController _countrySearchController = TextEditingController();
  bool _showCountryDropdown = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries(); // Fetch countries when screen loads
  }

  @override
  void dispose() {
    _countrySearchController.dispose();
    super.dispose();
  }

  // Filter countries based on search
  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(_countries);
      } else {
        _filteredCountries = _countries.where((country) =>
          country.countryName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  // Select country from search results
  void _selectCountry(CountriesModel country) {
    setState(() {
      _selectedCountryId = country.id;
      _countrySearchController.text = country.countryName;
      _showCountryDropdown = false;
    });
  }

  // Fetch countries from API
  Future<void> _fetchCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _countryErrorMessage = '';
    });

    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _countryErrorMessage = "No network connection. Please check your internet connection.";
        _isLoadingCountries = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_countryErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(BaseUrl.GETCOUNTRIES),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> jsonData;

        if (responseData is List) {
          jsonData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'];
          } else if (responseData.containsKey('countries')) {
            jsonData = responseData['countries'];
          } else if (responseData.containsKey('result')) {
            jsonData = responseData['result'];
          } else {
            throw FormatException('Unexpected response format: ${responseData.keys}');
          }
        } else {
          throw FormatException('Unexpected response type: ${responseData.runtimeType}');
        }

        setState(() {
          _countries = jsonData.map((json) => CountriesModel.fromJson(json)).toList();
          _filteredCountries = List.from(_countries);
          _isLoadingCountries = false;
        });
      } else {
        throw Exception('Failed to load countries. Status: ${response.statusCode}');
      }
    } on SocketException {
      _showErrorSnackBar('Network connection failed. Please check your internet connection.');
    } on TimeoutException {
      _showErrorSnackBar('Request timeout. Please try again.');
    } on FormatException {
      _showErrorSnackBar('Invalid data format. Server error');
    } on Exception {
      _showErrorSnackBar('Error loading countries. Server error');
    } finally {
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _signup() async {
    setState(() => _loading = true);

    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() => _loading = false);
      _showErrorSnackBar('No network connection. Please check your internet connection.');
      return;
    }

    try {
      final url = Uri.parse(BaseUrl.SIGNUP);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "refcode": refcode.isEmpty ? null : refcode, // Send null if empty (optional field)
          "email": email,
          "country": _selectedCountryId,
          "password": password,
          "password_confirmation": passwordConfirmation,
          "agreeTerms": _agreeTerms,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout. Please try again.');
        },
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? "Signup response received"),
          backgroundColor: data['error'] == false ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      if (response.statusCode == 200 && data['error'] == false) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
      if (response.statusCode == 201 && data['error'] == false) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            ),
          );
        }
      }
    } on SocketException {
      _showErrorSnackBar('Network connection failed. Please check your internet connection.');
    } on TimeoutException {
      _showErrorSnackBar('Request timeout. Please try again.');
    } on FormatException {
      _showErrorSnackBar('Invalid response format. Server error');
    } on Exception {
      _showErrorSnackBar('Signup failed. Server error');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      
      // Validate country selection
      if (_selectedCountryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a country"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Validate password confirmation
      if (password != passwordConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Validate terms agreement
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please agree to the Terms of Service and Privacy Policy"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      _signup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildSignupContent(),
    );
  }

  Widget _buildSignupContent() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary, 
          strokeWidth: 2.0
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSignupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Text(
              "Join Chloride MQTT Today",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "Create your account to get started",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 100,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Country Error Message Display ---
          if (_countryErrorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.orange[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _countryErrorMessage,
                      style: TextStyle(color: Colors.orange[700], fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          
          _buildNameField(),
          const SizedBox(height: 20),
          _buildRefCodeField(),
          const SizedBox(height: 20),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildCountryDropdown(),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildPasswordConfirmationField(),
          const SizedBox(height: 20),
          _buildTermsCheckbox(),
          const SizedBox(height: 32),
          _buildSignupButton(),
          const SizedBox(height: 24),
          _buildLoginOption(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Full Name",
        hintText: "Enter your full name",
        prefixIcon: Icon(
          Icons.person_outline,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
      onSaved: (val) => name = val ?? '',
    );
  }

  Widget _buildRefCodeField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Referral Code (Optional)",
        hintText: "Enter referral code if you have one",
        prefixIcon: Icon(
          Icons.card_giftcard_outlined,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      onSaved: (val) => refcode = val ?? '',
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Email Address",
        hintText: "Enter your email address",
        prefixIcon: Icon(
          Icons.email_outlined,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      keyboardType: TextInputType.emailAddress,
      validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
      onSaved: (val) => email = val ?? '',
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: TextFormField(
            controller: _countrySearchController,
            decoration: InputDecoration(
              labelText: 'Country',
              hintText: _isLoadingCountries ? 'Loading countries...' : 'Search and select your country',
              prefixIcon: Icon(Icons.public, color: AppColors.primary),
              suffixIcon: _countrySearchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        _countrySearchController.clear();
                        _selectedCountryId = null;
                        _showCountryDropdown = false;
                        _filteredCountries = List.from(_countries);
                      });
                    },
                  )
                : Icon(
                    _showCountryDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
            readOnly: _isLoadingCountries,
            onTap: () {
              if (!_isLoadingCountries) {
                setState(() {
                  _showCountryDropdown = !_showCountryDropdown;
                });
              }
            },
            onChanged: (value) {
              _filterCountries(value);
              setState(() {
                _showCountryDropdown = value.isNotEmpty;
                if (value.isEmpty) {
                  _selectedCountryId = null;
                }
              });
            },
            validator: (value) {
              if (_selectedCountryId == null) {
                return 'Please select a country';
              }
              return null;
            },
          ),
        ),
        
        // Dropdown list
        if (_showCountryDropdown && _filteredCountries.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  title: Text(
                    country.countryName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () => _selectCountry(country),
                  hoverColor: Colors.blue.shade50,
                );
              },
            ),
          ),
        
        // No results message
        if (_showCountryDropdown && _filteredCountries.isEmpty && _countrySearchController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No countries found matching "${_countrySearchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Create a password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      validator: (val) => val != null && val.length >= 4 ? null : 'Password must be at least 4 characters',
      onSaved: (val) => password = val ?? '',
    );
  }

  Widget _buildPasswordConfirmationField() {
    return TextFormField(
      obscureText: _obscurePasswordConfirmation,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        hintText: "Repeat your password",
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePasswordConfirmation ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () => setState(() => _obscurePasswordConfirmation = !_obscurePasswordConfirmation),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(fontSize: 16),
      validator: (val) => val != null && val.length >= 4 ? null : 'Password must be at least 4 characters',
      onSaved: (val) => passwordConfirmation = val ?? '',
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeTerms,
          onChanged: (value) {
            setState(() {
              _agreeTerms = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeTerms = !_agreeTerms;
              });
            },
            child: Text(
              "I agree to the Terms of Service and Privacy Policy",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: const Text(
        "CREATE ACCOUNT",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLoginOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Login",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}