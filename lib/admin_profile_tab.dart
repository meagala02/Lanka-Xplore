import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  static const Color _accent = Colors.tealAccent;

  // Profile controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Password controllers
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  // Visibility toggles
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  // State
  bool _loading = true;
  bool _saving = false;
  bool _changingPw = false;
  String _docId = '';
  Map<String, dynamic> _data = {};

  // Validation errors
  String? _nameError;
  String? _phoneError;
  String? _currentPwError;
  String? _newPwError;
  String? _confirmPwError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Query admins collection by email
      final snap = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        _docId = doc.id;
        _data = doc.data();
        _nameCtrl.text = _data['fullName'] ?? '';
        _phoneCtrl.text = _data['phone'] ?? '';
        _emailCtrl.text = _data['email'] ?? user.email ?? '';
      }
    } catch (e) {
      _showSnack('Error loading profile: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Validations ──────────────────────────────────────────────

  bool _validateProfile() {
    String? nameErr;
    String? phoneErr;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) {
      nameErr = 'Full name is required';
    } else if (name.length < 2) {
      nameErr = 'Name must be at least 2 characters';
    }

    if (phone.isEmpty) {
      phoneErr = 'Phone number is required';
    } else if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      phoneErr = 'Enter a valid phone number (07XXXXXXXX)';
    }

    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
    });

    return nameErr == null && phoneErr == null;
  }

  bool _validatePassword() {
    String? currentErr;
    String? newErr;
    String? confirmErr;

    final current = _currentPwCtrl.text.trim();
    final newPw = _newPwCtrl.text.trim();
    final confirm = _confirmPwCtrl.text.trim();

    if (current.isEmpty) currentErr = 'Current password is required';

    if (newPw.isEmpty) {
      newErr = 'New password is required';
    } else if (newPw.length < 6) {
      newErr = 'Password must be at least 6 characters';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(newPw)) {
      newErr = 'Password must contain at least one letter';
    } else if (!RegExp(r'[0-9]').hasMatch(newPw)) {
      newErr = 'Password must contain at least one number';
    } else if (newPw == current) {
      newErr = 'New password must differ from current password';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Please confirm your new password';
    } else if (newPw != confirm) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _currentPwError = currentErr;
      _newPwError = newErr;
      _confirmPwError = confirmErr;
    });

    return currentErr == null && newErr == null && confirmErr == null;
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_validateProfile()) return;
    if (_docId.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('admins').doc(_docId).update({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      _showSnack('Profile updated successfully!', Colors.green);
    } catch (e) {
      _showSnack('Error saving profile: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_validatePassword()) return;

    setState(() => _changingPw = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _currentPwCtrl.text.trim());

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPwCtrl.text.trim());

      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() {
        _currentPwError = null;
        _newPwError = null;
        _confirmPwError = null;
      });

      _showSnack('Password changed successfully!', Colors.green);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'Current password is incorrect.';
          setState(() => _currentPwError = msg);
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        case 'requires-recent-login':
          msg = 'Session expired. Please log out and log back in.';
          break;
        default:
          msg = 'Error: ${e.message}';
      }
      _showSnack(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar & Role ──
          Center(
            child: Column(children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: _accent, size: 40),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Text('ADMINISTRATOR',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
              ),
              const SizedBox(height: 4),
              Text(
                _data['userId'] ?? '',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // ── Profile Section Header ──
          _sectionHeader('PROFILE INFO', Icons.person_outline),
          const SizedBox(height: 14),

          _editableField(
            label: 'Full Name',
            controller: _nameCtrl,
            icon: Icons.person,
            error: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 12),
          _editableField(
            label: 'Phone',
            controller: _phoneCtrl,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            error: _phoneError,
            onChanged: (_) => setState(() => _phoneError = null),
          ),
          const SizedBox(height: 12),
          _readOnlyField('Email', _emailCtrl, Icons.email),

          const SizedBox(height: 24),
          _saveButton(),

          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),

          // ── Password Section ──
          _sectionHeader('CHANGE PASSWORD', Icons.lock_outline),
          const SizedBox(height: 6),
          const Text(
            'Minimum 6 characters, must include at least one letter and one number.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),

          _passwordField(
            label: 'Current Password',
            controller: _currentPwCtrl,
            visible: _showCurrentPw,
            toggle: () => setState(() => _showCurrentPw = !_showCurrentPw),
            error: _currentPwError,
            onChanged: (_) => setState(() => _currentPwError = null),
          ),
          const SizedBox(height: 12),
          _passwordField(
            label: 'New Password',
            controller: _newPwCtrl,
            visible: _showNewPw,
            toggle: () => setState(() => _showNewPw = !_showNewPw),
            error: _newPwError,
            onChanged: (_) => setState(() => _newPwError = null),
          ),
          const SizedBox(height: 12),
          _passwordField(
            label: 'Confirm New Password',
            controller: _confirmPwCtrl,
            visible: _showConfirmPw,
            toggle: () => setState(() => _showConfirmPw = !_showConfirmPw),
            error: _confirmPwError,
            onChanged: (_) => setState(() => _confirmPwError = null),
          ),

          const SizedBox(height: 20),
          _changePasswordButton(),

          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // ── Logout ──
          _logoutButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Widget Helpers ────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
      ]);

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          errorText: error,
          errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
          prefixIcon: Icon(icon, color: _accent, size: 18),
          filled: true,
          fillColor: const Color(0xFF161B22),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: error != null
                      ? Colors.orangeAccent.withOpacity(0.6)
                      : Colors.white10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orangeAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orangeAccent)),
        ),
      );

  Widget _readOnlyField(
          String label, TextEditingController ctrl, IconData icon) =>
      TextField(
        controller: ctrl,
        enabled: false,
        style: const TextStyle(color: Colors.white54, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          suffixIcon: const Tooltip(
            message: 'Email cannot be changed',
            child: Icon(Icons.lock_outline, color: Colors.white24, size: 16),
          ),
          filled: true,
          fillColor: Colors.black12,
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10)),
        ),
      );

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
    String? error,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        obscureText: !visible,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          errorText: error,
          errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
          prefixIcon: const Icon(Icons.lock_outline, color: _accent, size: 18),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 18),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: const Color(0xFF161B22),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: error != null
                      ? Colors.orangeAccent.withOpacity(0.6)
                      : Colors.white10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orangeAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orangeAccent)),
        ),
      );

  Widget _saveButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              disabledBackgroundColor: _accent.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.save_outlined, color: Colors.black, size: 18),
          label: Text(_saving ? 'SAVING...' : 'SAVE PROFILE',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _changePasswordButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _changingPw ? null : _changePassword,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              disabledBackgroundColor: Colors.deepPurpleAccent.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: _changingPw
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset_outlined,
                  color: Colors.white, size: 18),
          label: Text(_changingPw ? 'CHANGING...' : 'CHANGE PASSWORD',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _logoutButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.of(context).pushReplacementNamed('/');
          },
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
          label: const Text('LOG OUT',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      );
}
