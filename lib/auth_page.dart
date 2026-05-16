import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'visitor_home.dart';
import 'admin_dashboard.dart';
import 'notification_service.dart'; // FCM service

// ─── Country Model ────────────────────────────────────────────────────────────
class CountryInfo {
  final String name;
  final String code;
  final String flag;
  final String phoneRegex;
  final String passportRegex;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.flag,
    required this.phoneRegex,
    required this.passportRegex,
  });
}

// ─── Country Data ─────────────────────────────────────────────────────────────
const List<CountryInfo> kCountries = [
  CountryInfo(
      name: 'Sri Lanka',
      code: '+94',
      flag: '🇱🇰',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^(P[0-9]{7}|OL[0-9]{7}|D[0-9]{7})$'),
  CountryInfo(
      name: 'India',
      code: '+91',
      flag: '🇮🇳',
      phoneRegex: r'^[6-9][0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{7}$'),
  CountryInfo(
      name: 'USA',
      code: '+1',
      flag: '🇺🇸',
      phoneRegex: r'^[2-9][0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'UK',
      code: '+44',
      flag: '🇬🇧',
      phoneRegex: r'^[0-9]{10}$',
      passportRegex: r'^[0-9]{9}$'),
  CountryInfo(
      name: 'Australia',
      code: '+61',
      flag: '🇦🇺',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{7,8}$'),
  CountryInfo(
      name: 'Canada',
      code: '+1',
      flag: '🇨🇦',
      phoneRegex: r'^[2-9][0-9]{9}$',
      passportRegex: r'^[A-Z]{2}[0-9]{6}$'),
  CountryInfo(
      name: 'Germany',
      code: '+49',
      flag: '🇩🇪',
      phoneRegex: r'^[0-9]{10,11}$',
      passportRegex: r'^[CFGHJKLMNPRTVWXYZ0-9]{9}$'),
  CountryInfo(
      name: 'France',
      code: '+33',
      flag: '🇫🇷',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[0-9]{2}[A-Z]{2}[0-9]{5}$'),
  CountryInfo(
      name: 'China',
      code: '+86',
      flag: '🇨🇳',
      phoneRegex: r'^1[3-9][0-9]{9}$',
      passportRegex: r'^(E[0-9]{8}|G[0-9]{8})$'),
  CountryInfo(
      name: 'Japan',
      code: '+81',
      flag: '🇯🇵',
      phoneRegex: r'^[0-9]{10,11}$',
      passportRegex: r'^[A-Z]{2}[0-9]{7}$'),
  CountryInfo(
      name: 'South Korea',
      code: '+82',
      flag: '🇰🇷',
      phoneRegex: r'^[0-9]{9,10}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'Pakistan',
      code: '+92',
      flag: '🇵🇰',
      phoneRegex: r'^[0-9]{10}$',
      passportRegex: r'^[A-Z]{2}[0-9]{7}$'),
  CountryInfo(
      name: 'Bangladesh',
      code: '+880',
      flag: '🇧🇩',
      phoneRegex: r'^[0-9]{10}$',
      passportRegex: r'^[A-Z]{2}[0-9]{7}$'),
  CountryInfo(
      name: 'Maldives',
      code: '+960',
      flag: '🇲🇻',
      phoneRegex: r'^[0-9]{7}$',
      passportRegex: r'^[A-Z][0-9]{7}$'),
  CountryInfo(
      name: 'Singapore',
      code: '+65',
      flag: '🇸🇬',
      phoneRegex: r'^[89][0-9]{7}$',
      passportRegex: r'^[A-Z][0-9]{7}[A-Z]$'),
  CountryInfo(
      name: 'Malaysia',
      code: '+60',
      flag: '🇲🇾',
      phoneRegex: r'^[0-9]{9,10}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'UAE',
      code: '+971',
      flag: '🇦🇪',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{7}$'),
  CountryInfo(
      name: 'Saudi Arabia',
      code: '+966',
      flag: '🇸🇦',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'Italy',
      code: '+39',
      flag: '🇮🇹',
      phoneRegex: r'^[0-9]{9,10}$',
      passportRegex: r'^[A-Z]{2}[0-9]{7}$'),
  CountryInfo(
      name: 'Spain',
      code: '+34',
      flag: '🇪🇸',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[A-Z]{3}[0-9]{6}$'),
  CountryInfo(
      name: 'Russia',
      code: '+7',
      flag: '🇷🇺',
      phoneRegex: r'^[0-9]{10}$',
      passportRegex: r'^[0-9]{9}$'),
  CountryInfo(
      name: 'Brazil',
      code: '+55',
      flag: '🇧🇷',
      phoneRegex: r'^[0-9]{10,11}$',
      passportRegex: r'^[A-Z]{2}[0-9]{6}$'),
  CountryInfo(
      name: 'South Africa',
      code: '+27',
      flag: '🇿🇦',
      phoneRegex: r'^[0-9]{9}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'Nigeria',
      code: '+234',
      flag: '🇳🇬',
      phoneRegex: r'^[0-9]{10}$',
      passportRegex: r'^[A-Z][0-9]{8}$'),
  CountryInfo(
      name: 'Other',
      code: '+00',
      flag: '🌍',
      phoneRegex: r'^[0-9]{6,15}$',
      passportRegex: r'^[A-Z0-9]{6,9}$'),
];

// ─── AuthPage ─────────────────────────────────────────────────────────────────
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isForeigner = false;
  bool _isLoading = false;
  bool _showPassRules = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Selected countries
  CountryInfo _selectedPhoneCountry = kCountries.first; // phone flag
  CountryInfo _selectedForeignerCountry = kCountries[2]; // foreigner country

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Field-level error messages
  String? _nameErr, _phoneErr, _idErr, _emailErr, _passErr, _confirmErr;

  // ── Password rule getters ─────────────────────────────────────────────────
  bool get _hasLength => _passCtrl.text.length >= 10;
  bool get _hasUpper => _passCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _passCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _passCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSymbol =>
      _passCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _allRulesMet =>
      _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSymbol;

  // ── Validators ────────────────────────────────────────────────────────────
  bool _isValidEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  bool _isStrongPassword(String p) =>
      p.length >= 10 &&
      p.contains(RegExp(r'[A-Z]')) &&
      p.contains(RegExp(r'[a-z]')) &&
      p.contains(RegExp(r'[0-9]')) &&
      p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  bool _isValidNIC(String nic) =>
      RegExp(r'^\d{12}$').hasMatch(nic) ||
      RegExp(r'^\d{9}[VvXx]$').hasMatch(nic);

  bool _isValidPassport(String passport, CountryInfo country) =>
      RegExp(country.passportRegex, caseSensitive: false).hasMatch(passport);

  bool _isValidPhone(String phone, CountryInfo country) =>
      RegExp(country.phoneRegex).hasMatch(phone);

  // ── Real-time validators ──────────────────────────────────────────────────
  void _validatePhone(String v) => setState(() {
        _phoneErr = v.isEmpty
            ? null
            : _isValidPhone(v, _selectedPhoneCountry)
                ? null
                : 'Enter valid number';
      });

  void _validateEmail(String v) => setState(() {
        _emailErr = v.isEmpty
            ? null
            : _isValidEmail(v)
                ? null
                : 'Please enter valid mail address';
      });

  void _validatePass(String v) => setState(() {
        _passErr = null;
        if (_confirmCtrl.text.isNotEmpty) _validateConfirm(_confirmCtrl.text);
      });

  void _validateConfirm(String v) => setState(() {
        _confirmErr = v.isEmpty
            ? null
            : v == _passCtrl.text
                ? null
                : 'Passwords do not match';
      });

  void _validateNicOrPassport(String v) => setState(() {
        if (!_isForeigner) {
          _idErr = v.isEmpty
              ? null
              : _isValidNIC(v)
                  ? null
                  : 'Please enter valid NIC number';
        } else {
          _idErr = v.isEmpty
              ? null
              : _isValidPassport(v, _selectedForeignerCountry)
                  ? null
                  : 'Please enter valid passport number';
        }
      });

  // ── Full form validation before submit ────────────────────────────────────
  bool _validateAll() {
    bool ok = true;
    setState(() {
      _nameErr =
          _fullNameCtrl.text.trim().isEmpty ? 'Please fill the field' : null;
      if (_nameErr != null) ok = false;

      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _phoneErr = 'Please fill the field';
        ok = false;
      } else if (!_isValidPhone(phone, _selectedPhoneCountry)) {
        _phoneErr = 'Enter valid number';
        ok = false;
      } else {
        _phoneErr = null;
      }

      final id = _idCtrl.text.trim();
      if (id.isEmpty) {
        _idErr = 'Please fill the field';
        ok = false;
      } else if (!_isForeigner && !_isValidNIC(id)) {
        _idErr = 'Please enter valid NIC number';
        ok = false;
      } else if (_isForeigner &&
          !_isValidPassport(id, _selectedForeignerCountry)) {
        _idErr = 'Please enter valid passport number';
        ok = false;
      } else {
        _idErr = null;
      }

      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        _emailErr = 'Please fill the field';
        ok = false;
      } else if (!_isValidEmail(email)) {
        _emailErr = 'Please enter valid mail address';
        ok = false;
      } else {
        _emailErr = null;
      }

      if (_passCtrl.text.isEmpty) {
        _passErr = 'Please fill the field';
        ok = false;
      } else if (!_isStrongPassword(_passCtrl.text)) {
        _passErr = 'Password does not meet requirements';
        ok = false;
      } else {
        _passErr = null;
      }

      if (_confirmCtrl.text.isEmpty) {
        _confirmErr = 'Please fill the field';
        ok = false;
      } else if (_confirmCtrl.text != _passCtrl.text) {
        _confirmErr = 'Passwords do not match';
        ok = false;
      } else {
        _confirmErr = null;
      }
    });
    return ok;
  }

  // ── Main auth handler ─────────────────────────────────────────────────────
  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (_isLogin) {
      if (email.isEmpty || pass.isEmpty) {
        _showMsg('Please fill in all required fields');
        return;
      }
      setState(() => _isLoading = true);
      try {
        final cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);

        final uid = cred.user!.uid;
        DocumentSnapshot? userDoc;
        String finalRole = '';

        List<String> collections = [
          'admins',
          'users',
          'guides',
          'riders',
          'hotels'
        ];

        for (String col in collections) {
          final doc =
              await FirebaseFirestore.instance.collection(col).doc(uid).get();
          if (doc.exists) {
            userDoc = doc;

            try {
              finalRole = doc.get('role');
            } catch (e) {
              finalRole = col; // admins, guides, riders etc.
            }
            break;
          }
        }

        if (userDoc != null) {
          await NotificationService.saveTokenToFirestore(uid);

          if (finalRole.toLowerCase().contains('admin')) {
            _navigateTo(const AdminDashboard());
          } else {
            _navigateTo(VisitorHomePage(isLoggedIn: true, userRole: finalRole));
          }
        } else {
          await FirebaseAuth.instance.signOut();
          _showMsg('User profile not found in database!');
        }
      } on FirebaseAuthException catch (e) {
        print("Firebase Auth Error: ${e.code}");
        _showMsg(e.message ?? 'Authentication Error');
      } catch (e) {
        print("General Error: $e");
        _showMsg('An unexpected error occurred');
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    // REGISTER
    if (!_validateAll()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final fullPhone =
          '${_selectedPhoneCountry.code}${_phoneCtrl.text.trim()}';

      // Save user to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'fullName': _fullNameCtrl.text.trim(),
        'email': email,
        'role': 'tourist',
        'status': 'active',
        'isForeigner': _isForeigner,
        'country': _isForeigner ? _selectedForeignerCountry.name : 'Sri Lanka',
        'phone': fullPhone,
        'idNumber': _idCtrl.text.trim().toUpperCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save FCM token + send welcome notification
      await NotificationService.saveTokenToFirestore(cred.user!.uid);
      await NotificationService.sendWelcomeNotification(cred.user!.uid);

      _navigateTo(const VisitorHomePage(isLoggedIn: true, userRole: 'tourist'));
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? 'Registration Error');
    } catch (_) {
      _showMsg('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget page) => Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => page), (_) => false);

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _clearErrors() {
    _nameErr = _phoneErr = _idErr = _emailErr = _passErr = _confirmErr = null;
    _showPassRules = false;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset('assets/sl.jpg',
              fit: BoxFit.cover, alignment: const Alignment(0, 0.4)),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C3E50), Color(0xFF000428)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title ──────────────────────────────────────────────
                  Text(
                    _isLogin ? 'WELCOME BACK' : 'CREATE ACCOUNT',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? 'Sign in to continue' : 'Join our community',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // ── Register-only fields ───────────────────────────────
                  if (!_isLogin) ...[
                    // Full Name
                    _buildField(
                      _fullNameCtrl,
                      'Full Name',
                      Icons.person_outline,
                      errorText: _nameErr,
                      onChanged: (v) => setState(() => _nameErr =
                          v.trim().isEmpty ? 'Please fill the field' : null),
                    ),
                    const SizedBox(height: 15),

                    // Foreigner toggle
                    Row(children: [
                      const Text('Are you a foreigner?',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      Switch(
                        value: _isForeigner,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) => setState(() {
                          _isForeigner = val;
                          _idErr = null;
                          _idCtrl.clear();
                        }),
                      ),
                    ]),
                    const SizedBox(height: 15),

                    // Phone with country code
                    _buildPhoneField(),
                    const SizedBox(height: 15),

                    // Foreigner country selector
                    if (_isForeigner) ...[
                      _buildForeignerCountryRow(),
                      const SizedBox(height: 15),
                    ],

                    // NIC / Passport
                    _buildField(
                      _idCtrl,
                      _isForeigner ? 'Passport Number' : 'NIC Number',
                      Icons.badge_outlined,
                      errorText: _idErr,
                      onChanged: _validateNicOrPassport,
                    ),
                    const SizedBox(height: 15),
                  ],

                  // ── Email ──────────────────────────────────────────────
                  _buildField(
                    _emailCtrl,
                    'Email Address',
                    Icons.email_outlined,
                    errorText: _emailErr,
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 15),

                  // ── Password ───────────────────────────────────────────
                  _buildField(
                    _passCtrl,
                    'Password',
                    Icons.lock_outline,
                    isPass: true,
                    obscure: _obscurePass,
                    toggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    errorText: _passErr,
                    onChanged: _validatePass,
                    onTap: () => setState(() => _showPassRules = true),
                  ),

                  // Password rules widget
                  if (!_isLogin && _showPassRules) ...[
                    const SizedBox(height: 8),
                    _buildPasswordRules(),
                  ],

                  // ── Confirm Password ───────────────────────────────────
                  if (!_isLogin) ...[
                    const SizedBox(height: 15),
                    _buildField(
                      _confirmCtrl,
                      'Confirm Password',
                      Icons.lock_reset,
                      isPass: true,
                      obscure: _obscureConfirm,
                      toggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      errorText: _confirmErr,
                      onChanged: _validateConfirm,
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Submit button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade400,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLogin ? 'LOGIN' : 'REGISTER',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ── Toggle login/register ──────────────────────────────
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _clearErrors();
                    }),
                    child: Text(
                      _isLogin
                          ? 'New to Lanka Xplore? Create Account'
                          : 'Already have an account? Sign In',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Phone field with country code dropdown ───────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _phoneErr != null
                  ? Colors.redAccent
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(children: [
            // Country code dropdown
            _buildCountryDropdown(
              selected: _selectedPhoneCountry,
              showDialCode: true,
              onChanged: (c) => setState(() {
                _selectedPhoneCountry = c!;
                if (_phoneCtrl.text.isNotEmpty) _validatePhone(_phoneCtrl.text);
              }),
            ),
            Container(
                width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                onChanged: _validatePhone,
                decoration: InputDecoration(
                  hintText: 'Mobile Number',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ]),
        ),
        if (_phoneErr != null) _buildErrorText(_phoneErr!),
      ],
    );
  }

  // ─── Foreigner country selector ───────────────────────────────────────────
  Widget _buildForeignerCountryRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: _buildCountryDropdown(
        selected: _selectedForeignerCountry,
        showDialCode: false,
        onChanged: (c) => setState(() {
          _selectedForeignerCountry = c!;
          if (_idCtrl.text.isNotEmpty) _validateNicOrPassport(_idCtrl.text);
        }),
      ),
    );
  }

  // ─── Country dropdown ─────────────────────────────────────────────────────
  Widget _buildCountryDropdown({
    required CountryInfo selected,
    required ValueChanged<CountryInfo?> onChanged,
    bool showDialCode = true,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<CountryInfo>(
        value: selected,
        dropdownColor: const Color(0xFF1E2A38),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
        items: kCountries
            .map((c) => DropdownMenuItem<CountryInfo>(
                  value: c,
                  child: Text(
                    showDialCode
                        ? '${c.flag} ${c.code}'
                        : '${c.flag} ${c.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ))
            .toList(),
        selectedItemBuilder: (_) => kCountries
            .map((c) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Center(
                    child: Text(
                      showDialCode
                          ? '${c.flag} ${c.code}'
                          : '${c.flag} ${c.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ─── Password rules widget ────────────────────────────────────────────────
  Widget _buildPasswordRules() {
    if (_allRulesMet) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleRow(_hasLength, 'At least 10 characters'),
          _ruleRow(_hasUpper, 'At least one uppercase letter (A-Z)'),
          _ruleRow(_hasLower, 'At least one lowercase letter (a-z)'),
          _ruleRow(_hasDigit, 'At least one number (0-9)'),
          _ruleRow(_hasSymbol, 'At least one symbol (!@#\$%…)'),
        ],
      ),
    );
  }

  Widget _ruleRow(bool met, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(met ? Icons.check_circle : Icons.cancel,
            size: 16, color: met ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: met ? Colors.greenAccent : Colors.white54,
                fontSize: 12)),
      ]),
    );
  }

  // ─── Generic text field ───────────────────────────────────────────────────
  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPass ? obscure : false,
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(icon, color: Colors.blueAccent.shade100),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54),
                    onPressed: toggleObscure,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.redAccent
                        : Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.redAccent
                        : Colors.blueAccent,
                    width: 2)),
          ),
        ),
        if (errorText != null) _buildErrorText(errorText),
      ],
    );
  }

  Widget _buildErrorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 5, left: 12),
        child: Text(msg,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      );
}
