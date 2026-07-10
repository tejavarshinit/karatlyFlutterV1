import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/api/gold_user_registration_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';
import 'package:dio/dio.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = false;
  bool _acceptedTerms = false;
  String? _error;

  // State / City dropdown
  List<Map<String, String>> _states = [];
  List<Map<String, String>> _cities = [];
  Map<String, String>? _selectedState;
  Map<String, String>? _selectedCity;
  bool _loadingStates = true;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStates() async {
    setState(() => _loadingStates = true);
    try {
      final dio = ref.read(dioAugmontProvider);
      final api = GoldUserRegistrationApi(dio);
      final result = await api.fetchStates();
      if (result['ok'] == true && mounted) {
        final states = (result['states'] as List).cast<Map<String, String>>();
        setState(() => _states = states);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingStates = false);
  }

  Future<void> _loadCities(String stateId) async {
    setState(() => _loadingCities = true);
    try {
      final dio = ref.read(dioAugmontProvider);
      final api = GoldUserRegistrationApi(dio);
      final result = await api.fetchCities(stateId);
      if (result['ok'] == true && mounted) {
        final cities = (result['cities'] as List).cast<Map<String, String>>();
        setState(() => _cities = cities);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCities = false);
  }

  String _normalizeMobile(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('0091')) digits = digits.substring(4);
    if (digits.length > 10 && digits.startsWith('91')) digits = digits.substring(2);
    if (digits.length > 10 && digits.startsWith('0')) digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > 10) digits = digits.substring(digits.length - 10);
    return digits;
  }

  String? _validateForm() {
    final fullName = _fullNameController.text.trim();
    final mobile = _normalizeMobile(_mobileController.text);
    final dob = _dobController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (fullName.isEmpty) return 'Full name is required';
    if (!RegExp(r"^[A-Za-z .']+$").hasMatch(fullName)) return 'Full name should only contain letters';
    if (mobile.length != 10) return 'Enter a valid 10-digit mobile number';
    if (!RegExp(r'^[6-9]').hasMatch(mobile)) return 'Mobile number must start with 6, 7, 8, or 9';
    if (dob.isEmpty) return 'Select a valid date of birth';
    if (_selectedState == null) return 'Select a state';
    if (_selectedCity == null) return 'Select a city';
    if (pincode.length != 6) return 'Enter a valid 6-digit pincode';
    if (!_acceptedTerms) return 'Please agree to the Terms and Conditions before continuing.';
    return null;
  }

  String _formatDobForApi(String value) {
    final dateValue = value.trim();
    final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dateValue);
    if (isoMatch != null) {
      return '${isoMatch.group(3)}-${isoMatch.group(2)}-${isoMatch.group(1)}';
    }
    return dateValue;
  }

  Future<void> _sendOtp() async {
    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _normalizeMobile(_mobileController.text);
    final dob = _dobController.text.trim();
    final pincode = _pincodeController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).sendOtp(
        mobileNumber: mobile,
        email: email,
        fullName: fullName,
        dateOfBirth: dob,
        type: 'register',
      );

      if (mounted) {
        final success = result['ok'] == true || result['success'] == true;
        final alreadyRegistered = result['alreadyRegistered'] == true;

        if (alreadyRegistered) {
          setState(() => _error = 'This mobile number is already registered. Please login instead.');
        } else if (success) {
          // Save pending registration profile
          await LocalStorageService.setPendingRegistrationProfile({
            'fullName': fullName,
            'mobileNumber': mobile,
            'email': email,
            'dateOfBirth': _formatDobForApi(dob),
            'stateId': _selectedState!['id'],
            'stateName': _selectedState!['name'],
            'cityId': _selectedCity!['id'],
            'cityName': _selectedCity!['name'],
            'pinCode': pincode,
          });

          if (mounted) {
            GoRouter.of(context).push(AppRoutes.otp, extra: {
              'mobileNumber': mobile,
              'type': 'register',
              'email': email,
              'fullName': fullName,
              'dateOfBirth': _formatDobForApi(dob),
            });
          }
        } else {
          setState(() => _error = result['message']?.toString() ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Unable to send OTP. Please check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.97, -1.0),
            radius: 1.25,
            colors: [Color(0xFF4A3A1E), Color(0xFF000000)],
            stops: [0.0, 0.9945],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.8),
                      ),
                      child: const Icon(Icons.chevron_left, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [Color(0xFF3D2600), Color(0xFFB17B21), Color(0xFF3D2600)]),
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                      child: const Center(
                        child: Text('K', style: TextStyle(fontFamily: 'Georgia', fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF7CD57))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7D5800)),
                    color: const Color(0xFF161000),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 6),
                      Text('CREATE ACCOUNT', style: TextStyle(fontSize: 12, color: Colors.white, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'STEP 1 OF 2',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999), letterSpacing: 3),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'Start your ',
                    style: TextStyle(fontFamily: 'Playfair Display', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    children: [
                      TextSpan(text: 'Gold', style: TextStyle(color: Color(0xFFD9A639))),
                      TextSpan(text: ' journey'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 39, height: 1, color: const Color(0xFF6A511C)),
                    const SizedBox(width: 12),
                    Transform.rotate(angle: 0.7854, child: Container(width: 8, height: 8, color: const Color(0xFFB57F23))),
                    const SizedBox(width: 12),
                    Container(width: 39, height: 1, color: const Color(0xFF6A511C)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create an account to buy, sell, and manage your precious metals',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFFFF6D9)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
                  ),
                ],
                const SizedBox(height: 20),
                _buildField(_fullNameController, 'Full name *', TextInputType.name),
                const SizedBox(height: 12),
                _buildField(_emailController, 'Email', TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildField(_mobileController, 'Mobile number *', TextInputType.phone, maxLength: 10),
                const SizedBox(height: 12),
                _buildField(_dobController, 'Date of birth (DD-MM-YYYY)', TextInputType.datetime),
                const SizedBox(height: 12),
                _buildStateDropdown(),
                const SizedBox(height: 12),
                _buildCityDropdown(),
                const SizedBox(height: 12),
                _buildField(_pincodeController, 'Pincode', TextInputType.number, maxLength: 6),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: _acceptedTerms ? const Color(0xFFE8B438) : const Color(0xFF666666)),
                          color: _acceptedTerms ? const Color(0xFFE8B438) : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: _acceptedTerms ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "I agree to Karatly's Terms and Conditions",
                          style: TextStyle(fontSize: 11, height: 1.5, color: const Color(0xFFBDB6A0).withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isLoading ? null : _sendOtp,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(colors: [Color(0xFFF7CD57), Color(0xFFE5AF35), Color(0xFFB57F23)]),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLoading ? 'Sending...' : 'Send OTP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
                        if (!_isLoading) ...[const SizedBox(width: 12), const Icon(Icons.arrow_forward, size: 20, color: Colors.black)],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFFFF6D9))),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFE8B438))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, TextInputType type, {int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 16, color: Color(0xFFFFF6D9)),
      onChanged: (v) {
        if (type == TextInputType.phone || type == TextInputType.number) {
          final digits = v.replaceAll(RegExp(r'\D'), '');
          if (v != digits) {
            controller.text = digits;
            controller.selection = TextSelection.fromPosition(TextPosition(offset: digits.length));
          }
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(color: Color(0xFF5E5B5B)),
        filled: true,
        fillColor: const Color(0xFF1A1510),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return _loadingStates
        ? _buildDisabledField('Loading states...')
        : DropdownButtonFormField<Map<String, String>>(
            value: _selectedState,
            dropdownColor: const Color(0xFF1A1510),
            style: const TextStyle(fontSize: 16, color: Color(0xFFFFF6D9)),
            hint: const Text('State *', style: TextStyle(color: Color(0xFF5E5B5B))),
            isExpanded: true,
            items: _states.map((state) {
              return DropdownMenuItem(
                value: state,
                child: Text(state['name'] ?? ''),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedState = val;
                _selectedCity = null;
                _cities = [];
              });
              if (val != null && val['id'] != null && val['id']!.isNotEmpty) {
                _loadCities(val['id']!);
              }
            },
            decoration: _dropdownDecoration(),
          );
  }

  Widget _buildCityDropdown() {
    if (_selectedState == null) {
      return _buildDisabledField('Select a state first');
    }
    if (_loadingCities) {
      return _buildDisabledField('Loading cities...');
    }
    if (_cities.isEmpty) {
      return _buildDisabledField('No cities available');
    }
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedCity,
      dropdownColor: const Color(0xFF1A1510),
      style: const TextStyle(fontSize: 16, color: Color(0xFFFFF6D9)),
      hint: const Text('City *', style: TextStyle(color: Color(0xFF5E5B5B))),
      isExpanded: true,
      items: _cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city['name'] ?? ''),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedCity = val);
      },
      decoration: _dropdownDecoration(),
    );
  }

  Widget _buildDisabledField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF666666)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Color(0xFF5E5B5B))),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      counterText: '',
      filled: true,
      fillColor: const Color(0xFF1A1510),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF666666))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
