import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class OnboardTab extends StatefulWidget {
  const OnboardTab({super.key});

  @override
  State<OnboardTab> createState() => _OnboardTabState();
}

class _OnboardTabState extends State<OnboardTab> {
  final List<Map<String, dynamic>> _userTypes = [
    {
      'label': 'Admin',
      'icon': Icons.admin_panel_settings,
      'color': Colors.redAccent,
      'collection': 'admins',
      'prefix': 'A'
    },
    {
      'label': 'Hotel',
      'icon': Icons.hotel,
      'color': Colors.orangeAccent,
      'collection': 'hotels',
      'prefix': 'H'
    },
    {
      'label': 'Rider',
      'icon': Icons.two_wheeler,
      'color': Colors.blueAccent,
      'collection': 'riders',
      'prefix': 'R'
    },
    {
      'label': 'Guide',
      'icon': Icons.tour,
      'color': Colors.greenAccent,
      'collection': 'guides',
      'prefix': 'G'
    },
  ];

  String? _validatePhone(String val) {
    if (val.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^07[0-9]{8}$').hasMatch(val))
      return 'Enter valid SL mobile number (07XXXXXXXX)';
    return null;
  }

  String? _validateNIC(String val) {
    if (val.isEmpty) return 'NIC number is required';
    if (!RegExp(r'^[0-9]{9}[vVxX]$').hasMatch(val) &&
        !RegExp(r'^[0-9]{12}$').hasMatch(val))
      return 'Invalid NIC (e.g. 123456789V or 200012345678)';
    return null;
  }

  String? _validateEmail(String val) {
    if (val.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(val))
      return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String val) {
    if (val.isEmpty) return 'Password is required';
    if (val.length < 8) return 'Minimum 8 characters required';
    if (!val.contains(RegExp(r'[A-Z]')))
      return 'Add at least one uppercase letter';
    if (!val.contains(RegExp(r'[a-z]')))
      return 'Add at least one lowercase letter';
    if (!val.contains(RegExp(r'[0-9]'))) return 'Add at least one number';
    if (!val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')))
      return 'Add at least one special character';
    return null;
  }

  String? _validateLicense(String val) {
    if (val.isEmpty) return 'License number is required';
    if (!RegExp(r'^[A-Z]{1,2}[0-9]{6,8}$').hasMatch(val))
      return 'Invalid SL license (e.g. B1234567)';
    return null;
  }

  String? _validateHotelLicense(String val) {
    if (val.isEmpty) return 'Hotel license number is required';
    if (val.length < 5) return 'Enter a valid license number';
    return null;
  }

  Future<String> _generateId(String prefix, String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return '$prefix${(snap.docs.length + 1).toString().padLeft(3, '0')}';
  }

  void _showRegistrationForm(Map<String, dynamic> userType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        switch (userType['label'] as String) {
          case 'Admin':
            return _AdminForm(
                color: userType['color'],
                collection: userType['collection'],
                prefix: userType['prefix'],
                generateId: _generateId,
                validatePhone: _validatePhone,
                validateNIC: _validateNIC,
                validateEmail: _validateEmail,
                validatePassword: _validatePassword);
          case 'Hotel':
            return _HotelForm(
                color: userType['color'],
                collection: userType['collection'],
                prefix: userType['prefix'],
                generateId: _generateId,
                validateEmail: _validateEmail,
                validatePassword: _validatePassword,
                validateHotelLicense: _validateHotelLicense);
          case 'Rider':
            return _RiderForm(
                color: userType['color'],
                collection: userType['collection'],
                prefix: userType['prefix'],
                generateId: _generateId,
                validatePhone: _validatePhone,
                validateNIC: _validateNIC,
                validateEmail: _validateEmail,
                validatePassword: _validatePassword,
                validateLicense: _validateLicense);
          case 'Guide':
            return _GuideForm(
                color: userType['color'],
                collection: userType['collection'],
                prefix: userType['prefix'],
                generateId: _generateId,
                validatePhone: _validatePhone,
                validateNIC: _validateNIC,
                validateEmail: _validateEmail,
                validatePassword: _validatePassword);
          default:
            return const SizedBox();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ONBOARD USERS",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5)),
          const SizedBox(height: 5),
          const Text("Register admins, hotels, riders, and guides",
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 25),
          ..._userTypes.map((type) => _UserTypeCard(
              type: type,
              color: type['color'] as Color,
              onAdd: () => _showRegistrationForm(type),
              collection: type['collection'] as String)),
        ],
      ),
    );
  }
}

// ─── USER TYPE CARD ───────────────────────────────────────────────────────────
class _UserTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final Color color;
  final VoidCallback onAdd;
  final String collection;

  const _UserTypeCard(
      {required this.type,
      required this.color,
      required this.onAdd,
      required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
              color: const Color(0xFF1C2128),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      Icon(type['icon'] as IconData, color: color, size: 22)),
              title: Text(type['label'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              subtitle: Text("$count registered",
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                    onTap: onAdd,
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.4))),
                        child: Icon(Icons.add, color: color, size: 20))),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more, color: Colors.white38),
              ]),
              children: [
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text("No ${type['label']}s registered yet",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 13)))
                else
                  ...snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = data['userId'] ?? doc.id;
                    final name = data['fullName'] ?? data['hotelName'] ?? 'N/A';
                    final email = data['email'] ?? '';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          radius: 16,
                          child: Text(id.toString().substring(0, 1),
                              style: TextStyle(color: color, fontSize: 11))),
                      title: Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      subtitle: Text("$id • $email",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent, size: 16),
                          onPressed: () => doc.reference.delete()),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── SHARED FORM WIDGETS ──────────────────────────────────────────────────────
Widget _buildFormField(
    TextEditingController ctrl, String hint, String? Function(String) validator,
    {int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false}) {
  return StatefulBuilder(builder: (_, setS) {
    bool obs = obscure;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: StatefulBuilder(builder: (_, setS2) {
        return TextFormField(
          controller: ctrl,
          maxLines: obscure ? 1 : maxLines,
          obscureText: obscure ? obs : false,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) => validator(v ?? ''),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.black26,
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(obs ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38, size: 20),
                    onPressed: () => setS2(() => obs = !obs))
                : null,
            errorStyle:
                const TextStyle(color: Colors.orangeAccent, fontSize: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.tealAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.orangeAccent, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.orangeAccent, width: 1.5)),
          ),
        );
      }),
    );
  });
}

Widget _buildSectionTitle(String title, Color color) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(title,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1)),
    );

Widget _formHeader(String title, Color color, BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1)),
        IconButton(
            icon: const Icon(Icons.close, color: Colors.white38),
            onPressed: () => Navigator.pop(context)),
      ],
    );

Widget _buildSaveButton(Color color, String label, VoidCallback onPressed) =>
    Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 30),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );

Future<void> _createAuthAndSave({
  required BuildContext context,
  required String email,
  required String password,
  required String collection,
  required String role,
  required Map<String, dynamic> extraData,
  required Future<String> Function(String prefix, String collection) generateId,
  required String prefix,
}) async {
  // Secondary Firebase app create பண்ணு (admin session பாதிக்காம)
  FirebaseApp? secondaryApp;
  try {
    secondaryApp = await Firebase.initializeApp(
      name: 'secondary',
      options: Firebase.app().options, // Primary app-ஓட same options
    );
  } catch (e) {
    // Already exists-ஆ இருந்தா reuse பண்ணு
    secondaryApp = Firebase.app('secondary');
  }

  final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
  final cred = await secondaryAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  final String uid = cred.user!.uid;

  await secondaryAuth.signOut();

  final String customId = await generateId(prefix, collection);
  await FirebaseFirestore.instance.collection(collection).doc(uid).set({
    'uid': uid,
    'userId': customId,
    'role': role,
    'email': email,
    'createdAt': Timestamp.now(),
    ...extraData,
  });

  await secondaryApp.delete();
}

// ─── ADMIN FORM ───────────────────────────────────────────────────────────────
class _AdminForm extends StatefulWidget {
  final Color color;
  final String collection, prefix;
  final Future<String> Function(String, String) generateId;
  final String? Function(String) validatePhone,
      validateNIC,
      validateEmail,
      validatePassword;

  const _AdminForm(
      {required this.color,
      required this.collection,
      required this.prefix,
      required this.generateId,
      required this.validatePhone,
      required this.validateNIC,
      required this.validateEmail,
      required this.validatePassword});

  @override
  State<_AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<_AdminForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 25,
          left: 25,
          right: 25),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _formHeader("REGISTER ADMIN", widget.color, context),
            _buildSectionTitle("PERSONAL DETAILS", widget.color),
            _buildFormField(
                _nameCtrl,
                "Full Name",
                (v) => v.isEmpty
                    ? 'Full name is required'
                    : v.length < 3
                        ? 'Name too short'
                        : null),
            _buildFormField(
                _phoneCtrl, "Phone Number (07XXXXXXXX)", widget.validatePhone,
                keyboardType: TextInputType.phone),
            _buildFormField(_nicCtrl, "NIC Number", widget.validateNIC),
            _buildSectionTitle("ACCOUNT DETAILS", widget.color),
            _buildFormField(_emailCtrl, "Email Address", widget.validateEmail,
                keyboardType: TextInputType.emailAddress),
            _buildFormField(_passCtrl, "Password", widget.validatePassword,
                obscure: true),
            if (_saving)
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.redAccent))
            else
              _buildSaveButton(widget.color, "REGISTER ADMIN", () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _saving = true);
                try {
                  await _createAuthAndSave(
                    context: context,
                    email: _emailCtrl.text.trim(),
                    password: _passCtrl.text,
                    collection: widget.collection,
                    role: 'admin',
                    prefix: widget.prefix,
                    generateId: widget.generateId,
                    extraData: {
                      'fullName': _nameCtrl.text.trim(),
                      'phone': _phoneCtrl.text.trim(),
                      'nic': _nicCtrl.text.trim()
                    },
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "✓ Admin registered! Please re-login to continue your session."),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5)));
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Auth Error: ${e.message ?? e.code}"),
                        backgroundColor: Colors.red));
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red));
                }
                if (mounted) setState(() => _saving = false);
              }),
          ]),
        ),
      ),
    );
  }
}

// ─── HOTEL FORM ───────────────────────────────────────────────────────────────
class _HotelForm extends StatefulWidget {
  final Color color;
  final String collection, prefix;
  final Future<String> Function(String, String) generateId;
  final String? Function(String) validateEmail,
      validatePassword,
      validateHotelLicense;

  const _HotelForm(
      {required this.color,
      required this.collection,
      required this.prefix,
      required this.generateId,
      required this.validateEmail,
      required this.validatePassword,
      required this.validateHotelLicense});

  @override
  State<_HotelForm> createState() => _HotelFormState();
}

class _HotelFormState extends State<_HotelForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _licCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 25,
          left: 25,
          right: 25),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _formHeader("REGISTER HOTEL", widget.color, context),
            _buildSectionTitle("HOTEL DETAILS", widget.color),
            _buildFormField(_nameCtrl, "Hotel Name",
                (v) => v.isEmpty ? 'Hotel name is required' : null),
            _buildFormField(
                _licCtrl, "Hotel License Number", widget.validateHotelLicense),
            _buildFormField(_addressCtrl, "Hotel Address",
                (v) => v.isEmpty ? 'Address is required' : null,
                maxLines: 2),
            _buildSectionTitle("ACCOUNT DETAILS", widget.color),
            _buildFormField(_emailCtrl, "Hotel Email", widget.validateEmail,
                keyboardType: TextInputType.emailAddress),
            _buildFormField(_passCtrl, "Password", widget.validatePassword,
                obscure: true),
            if (_saving)
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.orangeAccent))
            else
              _buildSaveButton(widget.color, "REGISTER HOTEL", () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _saving = true);
                try {
                  await _createAuthAndSave(
                    context: context,
                    email: _emailCtrl.text.trim(),
                    password: _passCtrl.text,
                    collection: widget.collection,
                    role: 'hotel',
                    prefix: widget.prefix,
                    generateId: widget.generateId,
                    extraData: {
                      'hotelName': _nameCtrl.text.trim(),
                      'licenseNumber': _licCtrl.text.trim(),
                      'address': _addressCtrl.text.trim()
                    },
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "✓ Hotel registered! Please re-login to continue your session."),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5)));
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Auth Error: ${e.message ?? e.code}"),
                        backgroundColor: Colors.red));
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red));
                }
                if (mounted) setState(() => _saving = false);
              }),
          ]),
        ),
      ),
    );
  }
}

// ─── RIDER FORM ───────────────────────────────────────────────────────────────
class _RiderForm extends StatefulWidget {
  final Color color;
  final String collection, prefix;
  final Future<String> Function(String, String) generateId;
  final String? Function(String) validatePhone,
      validateNIC,
      validateEmail,
      validatePassword,
      validateLicense;

  const _RiderForm(
      {required this.color,
      required this.collection,
      required this.prefix,
      required this.generateId,
      required this.validatePhone,
      required this.validateNIC,
      required this.validateEmail,
      required this.validatePassword,
      required this.validateLicense});

  @override
  State<_RiderForm> createState() => _RiderFormState();
}

class _RiderFormState extends State<_RiderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _licCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  List<String> _selectedVehicles = [];
  final List<String> _vehicleTypes = [
    'MOTORCYCLE',
    'THREE-WHEELER',
    'CAR',
    'MINI VAN',
    'VAN'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 25,
          left: 25,
          right: 25),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _formHeader("REGISTER RIDER", widget.color, context),
            _buildSectionTitle("PERSONAL DETAILS", widget.color),
            _buildFormField(_nameCtrl, "Full Name",
                (v) => v.isEmpty ? 'Full name is required' : null),
            _buildFormField(
                _phoneCtrl, "Phone Number (07XXXXXXXX)", widget.validatePhone,
                keyboardType: TextInputType.phone),
            _buildFormField(_nicCtrl, "NIC Number", widget.validateNIC),
            _buildSectionTitle("VEHICLE DETAILS", widget.color),
            StatefulBuilder(
                builder: (ctx, setS) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Vehicle Types (select all that apply)",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _vehicleTypes.map((v) {
                                final sel = _selectedVehicles.contains(v);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      sel
                                          ? _selectedVehicles.remove(v)
                                          : _selectedVehicles.add(v);
                                    });
                                    setS(() {});
                                  },
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                          color: sel
                                              ? widget.color.withOpacity(0.2)
                                              : Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: sel
                                                  ? widget.color
                                                  : Colors.white10)),
                                      child: Text(v,
                                          style: TextStyle(
                                              color: sel
                                                  ? widget.color
                                                  : Colors.white38,
                                              fontSize: 12,
                                              fontWeight: sel
                                                  ? FontWeight.bold
                                                  : FontWeight.normal))),
                                );
                              }).toList()),
                          if (_selectedVehicles.isEmpty)
                            const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                    "Please select at least one vehicle type",
                                    style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 11))),
                        ])),
            _buildFormField(_licCtrl, "Driving License Number (e.g. B1234567)",
                widget.validateLicense),
            _buildSectionTitle("ACCOUNT DETAILS", widget.color),
            _buildFormField(_emailCtrl, "Email Address", widget.validateEmail,
                keyboardType: TextInputType.emailAddress),
            _buildFormField(_passCtrl, "Password", widget.validatePassword,
                obscure: true),
            _buildSaveButton(widget.color, "REGISTER RIDER", () async {
              if (_selectedVehicles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please select at least one vehicle type"),
                    backgroundColor: Colors.orangeAccent));
                return;
              }
              if (!_formKey.currentState!.validate()) return;
              try {
                await _createAuthAndSave(
                  context: context,
                  email: _emailCtrl.text.trim(),
                  password: _passCtrl.text,
                  collection: widget.collection,
                  role: 'rider',
                  prefix: widget.prefix,
                  generateId: widget.generateId,
                  extraData: {
                    'fullName': _nameCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim(),
                    'nic': _nicCtrl.text.trim(),
                    'vehicleTypes': _selectedVehicles,
                    'licenseNumber': _licCtrl.text.trim()
                  },
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "✓ Rider registered! Please re-login to continue your session."),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5)));
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Auth Error: ${e.message ?? e.code}"),
                      backgroundColor: Colors.red));
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            }),
          ]),
        ),
      ),
    );
  }
}

// ─── GUIDE FORM ───────────────────────────────────────────────────────────────
class _GuideForm extends StatefulWidget {
  final Color color;
  final String collection, prefix;
  final Future<String> Function(String, String) generateId;
  final String? Function(String) validatePhone,
      validateNIC,
      validateEmail,
      validatePassword;

  const _GuideForm(
      {required this.color,
      required this.collection,
      required this.prefix,
      required this.generateId,
      required this.validatePhone,
      required this.validateNIC,
      required this.validateEmail,
      required this.validatePassword});

  @override
  State<_GuideForm> createState() => _GuideFormState();
}

class _GuideFormState extends State<_GuideForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  List<String> _selectedLanguages = [];
  final List<String> _allLanguages = [
    'English',
    'Tamil',
    'Sinhala',
    'French',
    'Dutch',
    'Japanese',
    'Chinese',
    'Korean',
    'Spanish',
    'Arabic',
    'Russian',
    'Hindi'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 25,
          left: 25,
          right: 25),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _formHeader("REGISTER GUIDE", widget.color, context),
            _buildSectionTitle("PERSONAL DETAILS", widget.color),
            _buildFormField(_nameCtrl, "Full Name",
                (v) => v.isEmpty ? 'Full name is required' : null),
            _buildFormField(
                _phoneCtrl, "Phone Number (07XXXXXXXX)", widget.validatePhone,
                keyboardType: TextInputType.phone),
            _buildFormField(_nicCtrl, "NIC Number", widget.validateNIC),
            _buildSectionTitle("PROFESSIONAL DETAILS", widget.color),
            _buildFormField(_expCtrl, "Years of Experience", (v) {
              if (v.isEmpty) return 'Experience is required';
              final n = int.tryParse(v);
              if (n == null || n < 0) return 'Enter valid years (e.g. 3)';
              return null;
            }, keyboardType: TextInputType.number),
            StatefulBuilder(
                builder: (ctx, setS) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          const Text("Languages Spoken (select all that apply)",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allLanguages.map((lang) {
                                final sel = _selectedLanguages.contains(lang);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      sel
                                          ? _selectedLanguages.remove(lang)
                                          : _selectedLanguages.add(lang);
                                    });
                                    setS(() {});
                                  },
                                  child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                          color: sel
                                              ? widget.color.withOpacity(0.2)
                                              : Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: sel
                                                  ? widget.color
                                                  : Colors.white10)),
                                      child: Text(lang,
                                          style: TextStyle(
                                              color: sel
                                                  ? widget.color
                                                  : Colors.white38,
                                              fontSize: 12,
                                              fontWeight: sel
                                                  ? FontWeight.bold
                                                  : FontWeight.normal))),
                                );
                              }).toList()),
                          if (_selectedLanguages.isEmpty)
                            const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                    "Please select at least one language",
                                    style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 11))),
                        ])),
            _buildSectionTitle("ACCOUNT DETAILS", widget.color),
            _buildFormField(_emailCtrl, "Email Address", widget.validateEmail,
                keyboardType: TextInputType.emailAddress),
            _buildFormField(_passCtrl, "Password", widget.validatePassword,
                obscure: true),
            _buildSaveButton(widget.color, "REGISTER GUIDE", () async {
              if (_selectedLanguages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please select at least one language"),
                    backgroundColor: Colors.orangeAccent));
                return;
              }
              if (!_formKey.currentState!.validate()) return;
              try {
                await _createAuthAndSave(
                  context: context,
                  email: _emailCtrl.text.trim(),
                  password: _passCtrl.text,
                  collection: widget.collection,
                  role: 'guide',
                  prefix: widget.prefix,
                  generateId: widget.generateId,
                  extraData: {
                    'fullName': _nameCtrl.text.trim(),
                    'phone': _phoneCtrl.text.trim(),
                    'nic': _nicCtrl.text.trim(),
                    'experience': _expCtrl.text.trim(),
                    'languages': _selectedLanguages
                  },
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "✓ Guide registered! Please re-login to continue your session."),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5)));
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Auth Error: ${e.message ?? e.code}"),
                      backgroundColor: Colors.red));
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            }),
          ]),
        ),
      ),
    );
  }
}
