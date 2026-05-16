import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TouristDashboard extends StatefulWidget {
  const TouristDashboard({super.key});

  @override
  State<TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<TouristDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  bool _isOnline = true;
  StreamSubscription? _connectivitySub;

  Map<String, dynamic> _cachedProfile = {};
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  String _selectedCountryCode = '+94';

  String _filterBudget = 'All';
  String _filterType = 'All';
  String _filterLocation = 'All';

  // Cached bookings for offline
  List<Map<String, dynamic>> _cachedBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
    _loadUserProfile();
  }

  void _checkConnectivity() {
    Connectivity().checkConnectivity().then((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _cachedProfile = data;
          _nameCtrl.text = data['name'] ?? '';
          _phoneCtrl.text = data['phone'] ?? '';
          _countryCtrl.text = data['country'] ?? '';
          _selectedCountryCode = data['countryCode'] ?? '+94';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHubPage();
      case 1:
        return _buildExplorePage();
      case 2:
        return _buildBookingsPage();
      case 3:
        return _buildFeedbackPage();
      case 4:
        return _buildNotificationsPage();
      case 5:
        return _buildProfilePage();
      default:
        return _buildHubPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'TOURIST HUB',
      'EXPLORE',
      'MY BOOKINGS',
      'FEEDBACK',
      'NOTIFICATIONS',
      'PROFILE'
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _currentIndex == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white54, size: 18),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              fontSize: 15),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.emergency_share, color: Colors.redAccent),
              onPressed: _showSOSDialog,
            ),
          IconButton(
            icon: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: _isOnline ? Colors.tealAccent : Colors.redAccent,
              size: 18,
            ),
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white38, size: 18),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0D1117),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white24,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 9),
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: "Hub"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.travel_explore_rounded), label: "Explore"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.book_online_outlined), label: "Bookings"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined), label: "Feedback"),
          BottomNavigationBarItem(
            label: "Alerts",
            icon: _buildNotifBadge(),
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 0: HUB
  // ─────────────────────────────────────────────
  Widget _buildHubPage() {
    return Column(
      children: [
        _buildStatsRow(),
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(
                text: "TODAY",
                icon: Icon(Icons.calendar_today_outlined, size: 16)),
            Tab(text: "RATINGS", icon: Icon(Icons.star_outline, size: 16)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTodayTimeline(), _buildReviewList()],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _miniStat("Name", _cachedProfile['name'] ?? 'Tourist', Icons.person,
              Colors.tealAccent),
          _miniStat(
              "Weather", "29°C Sunny", Icons.wb_sunny, Colors.orangeAccent),
          _miniStat("Country", _cachedProfile['country'] ?? '-', Icons.flag,
              Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val, IconData icon, Color color) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const Spacer(),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTodayTimeline() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return const Center(
          child:
              Text('Not logged in', style: TextStyle(color: Colors.white38)));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text('No bookings yet',
                  style: TextStyle(color: Colors.white38)));
        }
        final sorted = docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });
        return ListView(
          padding: const EdgeInsets.all(20),
          children: sorted.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _timelineItem(d);
          }).toList(),
        );
      },
    );
  }

  Widget _timelineItem(Map<String, dynamic> d) {
    final status = d['status'] ?? 'pending';
    final statusColor = status == 'confirmed'
        ? Colors.tealAccent
        : status == 'cancelled'
            ? Colors.redAccent
            : Colors.orangeAccent;
    final dotColor = statusColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(Icons.circle, color: dotColor, size: 14),
            Container(width: 1, height: 80, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dotColor.withOpacity(0.2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(d['packageName'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Guide: ${d['guideName'] ?? '-'}  •  Rider: ${d['riderName'] ?? '-'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Text('Hotel: ${d['hotelName'] ?? '-'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                if (d['travelDate'] != null)
                  Text('Date: ${_formatDate(d['travelDate'])}',
                      style: TextStyle(color: statusColor, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) return DateFormat('MMM dd, yyyy').format(ts.toDate());
    return ts.toString();
  }

  Widget _buildReviewList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return const Center(
              child: Text('No bookings to rate',
                  style: TextStyle(color: Colors.white38)));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _reviewCard(
                d['guideName'] ?? 'Guide', 'Guide', Icons.person_pin, doc.id);
          }).toList(),
        );
      },
    );
  }

  Widget _reviewCard(
      String name, String type, IconData icon, String bookingId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 20),
          const SizedBox(width: 15),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 3),
            child:
                const Text("RATE", style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 1: EXPLORE (with filter)
  // ─────────────────────────────────────────────
  Widget _buildExplorePage() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(child: _buildPackagesGrid()),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: _filterDropdown(
                  'Budget',
                  _filterBudget,
                  [
                    'All',
                    'budget Rs20000-30000',
                    'mediumRs50000-80000',
                    'premiumRs100000-200000'
                  ],
                  (v) => setState(() => _filterBudget = v!))),
          const SizedBox(width: 8),
          Expanded(
              child: _filterDropdown(
                  'Type',
                  _filterType,
                  ['All', 'adventure', 'beach', 'cultural', 'nature'],
                  (v) => setState(() => _filterType = v!))),
          const SizedBox(width: 8),
          Expanded(
              child: _filterDropdown(
                  'Location',
                  _filterLocation,
                  [
                    'All',
                    'Colombo',
                    'Gampaha',
                    'Kalutara',
                    'Kandy',
                    'Matale',
                    'Nuwara Eliya',
                    'Galle',
                    'Matara',
                    'Hambantota',
                    'Jaffna',
                    'Kilinochchi',
                    'Mannar',
                    'Vavuniya',
                    'Mullaitivu',
                    'Batticaloa',
                    'Ampara',
                    'Trincomalee',
                    'Kurunegala',
                    'Puttalam',
                    'Anuradhapura',
                    'Polonnaruwa',
                    'Badulla',
                    'Moneragala',
                    'Ratnapura',
                    'Kegalle'
                  ],
                  (v) => setState(() => _filterLocation = v!))),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C2128),
          style: const TextStyle(color: Colors.white, fontSize: 11),
          icon: const Icon(Icons.arrow_drop_down,
              color: Colors.tealAccent, size: 18),
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      i == 'All' ? 'All $label' : _shortLabel(i),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _shortLabel(String s) {
    if (s.contains('budget')) return 'Budget';
    if (s.contains('medium')) return 'Medium';
    if (s.contains('premium')) return 'Premium';
    return s;
  }

  Widget _buildPackagesGrid() {
    Query query = FirebaseFirestore.instance.collection('packages');
    if (_filterBudget != 'All')
      query = query.where('budget', isEqualTo: _filterBudget);
    if (_filterType != 'All')
      query = query.where('type', isEqualTo: _filterType);
    if (_filterLocation != 'All')
      query = query.where('location', isEqualTo: _filterLocation);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)));
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(
              child: Text('No packages found',
                  style: TextStyle(color: Colors.white38)));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _packageCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _packageCard(Map<String, dynamic> data, String docId) {
    final imageUrl = data['imageUrl'] ?? '';
    return GestureDetector(
      onTap: () => _showPackageDetails(data, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _pkgPlaceholder())
                  : _pkgPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(data['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))),
                      _typeBadge(data['type'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on,
                        color: Colors.tealAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(data['location'] ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, color: Colors.white38, size: 12),
                    const SizedBox(width: 4),
                    Text(_shortDuration(data['duration'] ?? ''),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  Text(_shortBudget(data['budget'] ?? ''),
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pkgPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.teal.withOpacity(0.1),
      child: const Icon(Icons.landscape, color: Colors.tealAccent, size: 50),
    );
  }

  Widget _typeBadge(String type) {
    final colors = {
      'adventure': Colors.orange,
      'beach': Colors.blue,
      'cultural': Colors.purple,
      'nature': Colors.green
    };
    final color = colors[type.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Text(type, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  String _shortDuration(String dur) {
    if (dur.contains('day trip')) return '1 Day';
    if (dur.contains('weekend')) return '2-3 Days';
    if (dur.contains('long')) return '7+ Days';
    return dur;
  }

  String _shortBudget(String budget) {
    if (budget.contains('budget')) return 'LKR 20,000 - 30,000';
    if (budget.contains('medium')) return 'LKR 50,000 - 80,000';
    if (budget.contains('premium')) return 'LKR 100,000+';
    return budget;
  }

  void _showPackageDetails(Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((data['imageUrl'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(data['imageUrl'],
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _typeBadge(data['type'] ?? ''),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on,
                          color: Colors.tealAccent, size: 14),
                      Text(data['location'] ?? '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ]),
                    const SizedBox(height: 15),
                    Text(data['description'] ?? '',
                        style: const TextStyle(
                            color: Colors.white70, height: 1.5)),
                    const SizedBox(height: 15),
                    _detailRow(Icons.schedule, 'Duration',
                        _shortDuration(data['duration'] ?? '')),
                    _detailRow(Icons.payments, 'Budget',
                        _shortBudget(data['budget'] ?? '')),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showBookingForm(data, docId);
                        },
                        child: const Text('BOOK NOW',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: Colors.tealAccent, size: 16),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // BOOKING FORM
  // ─────────────────────────────────────────────
  void _showBookingForm(Map<String, dynamic> pkgData, String pkgDocId) {
    String selectedPackageId = pkgDocId;
    String selectedPackageName = pkgData['name'] ?? '';
    String selectedRiderId = '';
    String selectedRiderName = '';
    String selectedRiderPhone = '';
    String selectedGuideId = '';
    String selectedGuideName = '';
    String selectedGuidePhone = '';
    String selectedHotelId = '';
    String selectedHotelName = '';
    String selectedHotelPhone = '';
    String visitorCountry = _cachedProfile['country'] ?? '';
    DateTime? selectedDate;
    String phoneNumber = _cachedProfile['phone'] ?? '';
    String countryCode = _cachedProfile['countryCode'] ?? '+94';
    bool isPhoneValid = true;

    final touristName = _cachedProfile['name'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        '';
    final nameCtrl = TextEditingController(text: touristName);
    final countryCtrlLocal = TextEditingController(text: visitorCountry);
    final phoneCtrl = TextEditingController(text: phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setST) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BOOK YOUR TRIP',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1)),
                        IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white38),
                            onPressed: () => Navigator.pop(ctx2)),
                      ]),
                  const SizedBox(height: 15),
                  _sectionLabel('Package'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.4))),
                    child: Row(children: [
                      const Icon(Icons.landscape,
                          color: Colors.tealAccent, size: 18),
                      const SizedBox(width: 10),
                      Text(selectedPackageName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Your Name'),
                  _bookingTextField(nameCtrl, 'Full Name', Icons.person),
                  const SizedBox(height: 15),
                  _sectionLabel('Mobile Number'),
                  Row(children: [
                    _countryCodePicker(
                        countryCode, (val) => setST(() => countryCode = val)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) {
                        setST(() =>
                            isPhoneValid = _validatePhone(v, countryCode));
                        phoneNumber = v;
                      },
                      decoration: InputDecoration(
                        hintText: 'Phone number',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        errorText: !isPhoneValid
                            ? 'Invalid number for selected country'
                            : null,
                        errorStyle: const TextStyle(
                            color: Colors.orangeAccent, fontSize: 10),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 15),
                  _sectionLabel('Visitor Country'),
                  _bookingTextField(
                      countryCtrlLocal, 'Your country', Icons.flag),
                  const SizedBox(height: 15),
                  _sectionLabel('Travel Date'),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: now.add(const Duration(days: 1)),
                        firstDate: now.add(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                  primary: Colors.tealAccent)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setST(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selectedDate == null
                                ? Colors.white10
                                : Colors.tealAccent),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.tealAccent, size: 18),
                        const SizedBox(width: 10),
                        Text(
                            selectedDate == null
                                ? 'Select travel date'
                                : DateFormat('MMMM dd, yyyy')
                                    .format(selectedDate!),
                            style: TextStyle(
                                color: selectedDate == null
                                    ? Colors.white38
                                    : Colors.white)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Select Rider'),
                  _firebaseDropdown(
                    collection: 'riders',
                    hintText: 'Choose a rider',
                    displayBuilder: (data) {
                      final name = data['fullName'] ?? data['name'] ?? '';
                      final vehicles =
                          (data['vehicleTypes'] as List?)?.join(', ') ?? '';
                      return '$name${vehicles.isNotEmpty ? ' — $vehicles' : ''}';
                    },
                    onSelected: (id, data) => setST(() {
                      selectedRiderId = id;
                      selectedRiderName =
                          data['fullName'] ?? data['name'] ?? '';
                      selectedRiderPhone = data['phone'] ?? '';
                    }),
                    icon: Icons.directions_car,
                    currentValue:
                        selectedRiderId.isEmpty ? null : selectedRiderId,
                    onValueChanged: (v) =>
                        setST(() => selectedRiderId = v ?? ''),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Select Guide'),
                  _firebaseDropdown(
                    collection: 'guides',
                    hintText: 'Choose a guide',
                    displayBuilder: (data) {
                      final name = data['fullName'] ?? data['name'] ?? '';
                      final langs =
                          (data['languages'] as List?)?.join(', ') ?? '';
                      return '$name${langs.isNotEmpty ? ' — $langs' : ''}';
                    },
                    onSelected: (id, data) => setST(() {
                      selectedGuideId = id;
                      selectedGuideName =
                          data['fullName'] ?? data['name'] ?? '';
                      selectedGuidePhone = data['phone'] ?? '';
                    }),
                    icon: Icons.person_pin,
                    currentValue:
                        selectedGuideId.isEmpty ? null : selectedGuideId,
                    onValueChanged: (v) =>
                        setST(() => selectedGuideId = v ?? ''),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Select Hotel'),
                  _firebaseDropdown(
                    collection: 'hotels',
                    hintText: 'Choose a hotel',
                    displayBuilder: (data) {
                      final name = data['hotelName'] ??
                          data['fullName'] ??
                          data['name'] ??
                          '';
                      final addr = data['address'] ?? '';
                      return '$name${addr.isNotEmpty ? ' — $addr' : ''}';
                    },
                    onSelected: (id, data) => setST(() {
                      selectedHotelId = id;
                      selectedHotelName = data['hotelName'] ??
                          data['fullName'] ??
                          data['name'] ??
                          '';
                      selectedHotelPhone = data['phone'] ?? '';
                    }),
                    icon: Icons.hotel,
                    currentValue:
                        selectedHotelId.isEmpty ? null : selectedHotelId,
                    onValueChanged: (v) =>
                        setST(() => selectedHotelId = v ?? ''),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            countryCtrlLocal.text.trim().isEmpty ||
                            selectedDate == null ||
                            selectedRiderId.isEmpty ||
                            selectedGuideId.isEmpty ||
                            selectedHotelId.isEmpty) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: Colors.orangeAccent));
                          return;
                        }
                        if (!_validatePhone(phoneCtrl.text, countryCode)) {
                          setST(() => isPhoneValid = false);
                          return;
                        }
                        await _submitBooking(
                          ctx: ctx2,
                          packageId: selectedPackageId,
                          packageName: selectedPackageName,
                          touristName: nameCtrl.text.trim(),
                          phone: '$countryCode${phoneCtrl.text.trim()}',
                          visitorCountry: countryCtrlLocal.text.trim(),
                          travelDate: selectedDate!,
                          riderId: selectedRiderId,
                          riderName: selectedRiderName,
                          riderPhone: selectedRiderPhone,
                          guideId: selectedGuideId,
                          guideName: selectedGuideName,
                          guidePhone: selectedGuidePhone,
                          hotelId: selectedHotelId,
                          hotelName: selectedHotelName,
                          hotelPhone: selectedHotelPhone,
                        );
                      },
                      child: const Text('CONFIRM BOOKING',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }

  Widget _bookingTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.tealAccent)),
      ),
    );
  }

  Widget _countryCodePicker(String value, Function(String) onChanged) {
    final codes = [
      '+94',
      '+1',
      '+44',
      '+91',
      '+61',
      '+49',
      '+33',
      '+81',
      '+86',
      '+65'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1C2128),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: codes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  bool _validatePhone(String phone, String countryCode) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (countryCode == '+94')
      return cleaned.length == 9 || cleaned.length == 10;
    if (countryCode == '+1') return cleaned.length == 10;
    if (countryCode == '+44')
      return cleaned.length >= 9 && cleaned.length <= 11;
    if (countryCode == '+91') return cleaned.length == 10;
    return cleaned.length >= 7 && cleaned.length <= 12;
  }

  // ─── FIX: FirebaseDropdown — selectedValue now lives in the outer
  //     StatefulBuilder (setST from _showBookingForm) via a ValueNotifier
  //     so the UI refreshes correctly and validation passes.
  Widget _firebaseDropdown({
    required String collection,
    required String hintText,
    required String Function(Map<String, dynamic>) displayBuilder,
    required Function(String id, Map<String, dynamic> data) onSelected,
    required IconData icon,
    String? currentValue,
    required void Function(String?) onValueChanged,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Colors.tealAccent);

        final docs = snapshot.data!.docs;
        // Safety: if currentValue not in list, reset to null
        final validValue =
            docs.any((d) => d.id == currentValue) ? currentValue : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: validValue != null
                      ? Colors.tealAccent.withOpacity(0.5)
                      : Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF1C2128),
              hint: Row(children: [
                Icon(icon, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(hintText,
                    style: const TextStyle(color: Colors.white38, fontSize: 13))
              ]),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    displayBuilder(data),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                onValueChanged(id); // rebuilds outer StatefulBuilder
                if (id != null) {
                  final data = docs.firstWhere((d) => d.id == id).data()
                      as Map<String, dynamic>;
                  onSelected(id, data);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitBooking({
    required BuildContext ctx,
    required String packageId,
    required String packageName,
    required String touristName,
    required String phone,
    required String visitorCountry,
    required DateTime travelDate,
    required String riderId,
    required String riderName,
    required String riderPhone,
    required String guideId,
    required String guideName,
    required String guidePhone,
    required String hotelId,
    required String hotelName,
    required String hotelPhone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please login to book'),
            backgroundColor: Colors.redAccent));
      }
      return;
    }
    try {
      final bookingRef =
          await FirebaseFirestore.instance.collection('bookings').add({
        'userId': uid!,
        'packageId': packageId,
        'packageName': packageName,
        'touristName': touristName,
        'phone': phone,
        'visitorCountry': visitorCountry,
        'travelDate': Timestamp.fromDate(travelDate),
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'guideId': guideId,
        'guideName': guideName,
        'guidePhone': guidePhone,
        'hotelId': hotelId,
        'hotelName': hotelName,
        'hotelPhone': hotelPhone,
        'status': 'pending',
        // Per-role request status: pending → accepted / cancelled
        'guideRequestStatus': 'pending',
        'riderRequestStatus': 'pending',
        'hotelRequestStatus': 'pending',
        'createdAt': Timestamp.now(),
      });

      final travelDateFmt = DateFormat('MMM dd, yyyy').format(travelDate);
      final msg =
          'New booking from $touristName for $packageName on $travelDateFmt';

      for (final entry in [
        {'toId': guideId, 'toRole': 'guide'},
        {'toId': riderId, 'toRole': 'rider'},
        {'toId': hotelId, 'toRole': 'hotel'},
      ]) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toId': entry['toId'],
          'toRole': entry['toRole'],
          'bookingId': bookingRef.id,
          'packageName': packageName,
          'touristName': touristName,
          'touristPhone':
              phone, // ← FIX: guide/rider/hotel dashboard-ல் show ஆகும்
          'phone': phone, // ← backward compat
          'visitorCountry': visitorCountry,
          'travelDate': Timestamp.fromDate(travelDate),
          'message': msg,
          'read': false,
          'type': 'booking_request',
          'createdAt': Timestamp.now(),
        });
      }

      if (ctx.mounted) Navigator.pop(ctx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Booking submitted! Awaiting confirmation.'),
            backgroundColor: Colors.green));
        setState(() => _currentIndex = 2);
      }
    } catch (e, stack) {
      debugPrint('Booking error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  // ─────────────────────────────────────────────
  // PAGE 2: MY BOOKINGS — with separate request tables
  // ─────────────────────────────────────────────
  Widget _buildBookingsPage() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Offline mode: show cached list
    if (!_isOnline) {
      return _buildOfflineBookings();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: uid == null
          ? null
          : FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));

        final docs = snapshot.data!.docs;

        // Sort in memory by createdAt desc (no Firestore index needed)
        final sorted = docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });

        // Cache for offline
        _cachedBookings = sorted.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, ...data};
        }).toList();

        if (sorted.isEmpty)
          return const Center(
              child: Text('No bookings yet',
                  style: TextStyle(color: Colors.white38)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: sorted.map((doc) => _bookingCard(doc)).toList(),
        );
      },
    );
  }

  Widget _buildOfflineBookings() {
    if (_cachedBookings.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 40),
          const SizedBox(height: 10),
          const Text('Offline — No cached bookings',
              style: TextStyle(color: Colors.white38)),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
          child: const Row(children: [
            Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 14),
            SizedBox(width: 8),
            Text('Offline Mode — Showing cached bookings',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
          ]),
        ),
        ..._cachedBookings.map((d) => _offlineBookingCard(d)),
      ],
    );
  }

  Widget _offlineBookingCard(Map<String, dynamic> d) {
    final status = d['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Text(d['packageName'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
          _statusBadge(status, statusColor),
        ]),
        const Divider(color: Colors.white10, height: 20),
        _bookingRow(Icons.calendar_today, 'Date', _formatDate(d['travelDate'])),
        _bookingRow(Icons.person_pin, 'Guide', d['guideName'] ?? '-'),
        _bookingRow(Icons.directions_car, 'Rider', d['riderName'] ?? '-'),
        _bookingRow(Icons.hotel, 'Hotel', d['hotelName'] ?? '-'),
      ]),
    );
  }

  // Main booking card with per-role request status tables
  Widget _bookingCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final status = d['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final isConfirmed = status == 'confirmed';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Text(d['packageName'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
          _statusBadge(status, statusColor),
        ]),
        const SizedBox(height: 4),
        _bookingRow(Icons.calendar_today, 'Date', _formatDate(d['travelDate'])),
        _bookingRow(Icons.flag, 'Country', d['visitorCountry'] ?? '-'),

        const Divider(color: Colors.white10, height: 20),

        // Per-role request status tables
        const Text('REQUEST STATUS',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        _requestStatusTable(d),

        // Cancel button (online + confirmed only)
        if (isConfirmed && _isOnline) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(doc.id, d),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 11)),
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.redAccent, size: 16),
              label: const Text('CANCEL BOOKING',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ),
        ],
        if (!_isOnline && isConfirmed) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 13),
              SizedBox(width: 6),
              Text('Online required to cancel',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }

  /// Renders a 3-row table: Guide / Rider / Hotel with their per-role request status
  Widget _requestStatusTable(Map<String, dynamic> d) {
    final rows = [
      {
        'role': 'Guide',
        'name': d['guideName'] ?? '-',
        'status': d['guideRequestStatus'] ?? 'pending',
        'icon': Icons.person_pin,
      },
      {
        'role': 'Rider',
        'name': d['riderName'] ?? '-',
        'status': d['riderRequestStatus'] ?? 'pending',
        'icon': Icons.directions_car,
      },
      {
        'role': 'Hotel',
        'name': d['hotelName'] ?? '-',
        'status': d['hotelRequestStatus'] ?? 'pending',
        'icon': Icons.hotel,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final rs = row['status'] as String;
          final icon = row['icon'] as IconData;
          final rsColor = rs == 'accepted'
              ? Colors.tealAccent
              : rs == 'cancelled'
                  ? Colors.redAccent
                  : Colors.orangeAccent;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: i < rows.length - 1
                  ? const Border(bottom: BorderSide(color: Colors.white10))
                  : null,
            ),
            child: Row(children: [
              Icon(icon, color: Colors.white38, size: 15),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(row['role'] as String,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                    Text(row['name'] as String,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: rsColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(rs.toUpperCase(),
                    style: TextStyle(
                        color: rsColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.tealAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  Widget _bookingRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }

  Future<void> _cancelBooking(String bookingId, Map<String, dynamic> d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title:
            const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this booking?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'cancelled'});

    for (final entry in [
      {'toId': d['guideId'], 'toRole': 'guide'},
      {'toId': d['riderId'], 'toRole': 'rider'},
      {'toId': d['hotelId'], 'toRole': 'hotel'},
    ]) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toId': entry['toId'],
        'toRole': entry['toRole'],
        'bookingId': bookingId,
        'packageName': d['packageName'],
        'touristName': d['touristName'],
        'travelDate': d['travelDate'],
        'message':
            'CANCELLED: Booking for ${d['packageName']} by ${d['touristName']} has been cancelled.',
        'read': false,
        'type': 'cancellation',
        'createdAt': Timestamp.now(),
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking cancelled'), backgroundColor: Colors.redAccent));
  }

  // ─────────────────────────────────────────────
  // PAGE 3: FEEDBACK
  // ─────────────────────────────────────────────
  Widget _buildFeedbackPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _feedbackOptionCard(
          title: 'Rate Guide / Rider / Hotel',
          subtitle: 'Feedback for your service providers',
          icon: Icons.person_pin,
          color: Colors.tealAccent,
          onTap: () => _showServiceFeedbackForm(),
        ),
        const SizedBox(height: 15),
        _feedbackOptionCard(
          title: 'General Feedback',
          subtitle: 'Share your overall experience',
          icon: Icons.rate_review,
          color: Colors.blueAccent,
          onTap: () => _showGeneralFeedbackForm(),
        ),
      ],
    );
  }

  Widget _feedbackOptionCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }

  void _showServiceFeedbackForm() {
    String selectedType = 'guide';
    String selectedId = '';
    String selectedName = '';
    int stars = 0;
    final descCtrl = TextEditingController();
    final touristName = _cachedProfile['name'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setST) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SERVICE FEEDBACK',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1)),
                        IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white38),
                            onPressed: () => Navigator.pop(ctx2)),
                      ]),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.person,
                          color: Colors.tealAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(touristName,
                          style: const TextStyle(color: Colors.white)),
                    ]),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Who are you rating?'),
                  Row(
                      children: ['guide', 'rider', 'hotel']
                          .map(
                            (type) => GestureDetector(
                              onTap: () => setST(() {
                                selectedType = type;
                                selectedId = '';
                                selectedName = '';
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedType == type
                                      ? Colors.tealAccent.withOpacity(0.2)
                                      : Colors.black26,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: selectedType == type
                                          ? Colors.tealAccent
                                          : Colors.white10),
                                ),
                                child: Text(type.toUpperCase(),
                                    style: TextStyle(
                                        color: selectedType == type
                                            ? Colors.tealAccent
                                            : Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                          .toList()),
                  const SizedBox(height: 15),
                  _sectionLabel(
                      'Select ${selectedType[0].toUpperCase()}${selectedType.substring(1)}'),
                  _firebaseDropdown(
                    collection: '${selectedType}s',
                    hintText: 'Choose a $selectedType',
                    displayBuilder: (data) =>
                        data['fullName'] ??
                        data['hotelName'] ??
                        data['name'] ??
                        '',
                    onSelected: (id, data) => setST(() {
                      selectedId = id;
                      selectedName = data['fullName'] ??
                          data['hotelName'] ??
                          data['name'] ??
                          '';
                    }),
                    icon: selectedType == 'guide'
                        ? Icons.person_pin
                        : selectedType == 'rider'
                            ? Icons.directions_car
                            : Icons.hotel,
                    currentValue: selectedId.isEmpty ? null : selectedId,
                    onValueChanged: (v) => setST(() => selectedId = v ?? ''),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Rating'),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => IconButton(
                          icon: Icon(i < stars ? Icons.star : Icons.star_border,
                              color: Colors.amber, size: 36),
                          onPressed: () => setST(() => stars = i + 1),
                        ),
                      )),
                  const SizedBox(height: 10),
                  _sectionLabel('Reason / Comment *'),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tell us why...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.tealAccent)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (selectedId.isEmpty ||
                            stars == 0 ||
                            descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: Colors.orangeAccent));
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('feedback')
                            .add({
                          'type': 'service',
                          'serviceType': selectedType,
                          'serviceId': selectedId,
                          'serviceName': selectedName,
                          'touristName': touristName,
                          'stars': stars,
                          'description': descCtrl.text.trim(),
                          'createdAt': Timestamp.now(),
                        });
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Feedback submitted! Thank you.'),
                                backgroundColor: Colors.green));
                      },
                      child: const Text('SUBMIT FEEDBACK',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ]),
          ),
        ),
      ),
    );
  }

  void _showGeneralFeedbackForm() {
    int stars = 0;
    final descCtrl = TextEditingController();
    final touristName = _cachedProfile['name'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setST) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GENERAL FEEDBACK',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1)),
                        IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white38),
                            onPressed: () => Navigator.pop(ctx2)),
                      ]),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.person,
                          color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(touristName,
                          style: const TextStyle(color: Colors.white)),
                    ]),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel('Overall Rating'),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => IconButton(
                          icon: Icon(i < stars ? Icons.star : Icons.star_border,
                              color: Colors.amber, size: 36),
                          onPressed: () => setST(() => stars = i + 1),
                        ),
                      )),
                  const SizedBox(height: 10),
                  _sectionLabel('Describe Your Experience *'),
                  TextField(
                    controller: descCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Your overall experience with Lanka Xplore...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (stars == 0 || descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill all fields'),
                                  backgroundColor: Colors.orangeAccent));
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('feedback')
                            .add({
                          'type': 'general',
                          'touristName': touristName,
                          'stars': stars,
                          'description': descCtrl.text.trim(),
                          'createdAt': Timestamp.now(),
                        });
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Feedback submitted! Thank you.'),
                                backgroundColor: Colors.green));
                      },
                      child: const Text('SUBMIT FEEDBACK',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NOTIFICATION BADGE (bottom nav icon)
  // ─────────────────────────────────────────────
  Widget _buildNotifBadge() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Icon(Icons.notifications_outlined);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (_, snap) {
        final n = snap.data?.docs.length ?? 0;
        return Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.notifications_outlined),
          if (n > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]);
      },
    );
  }

  // ─────────────────────────────────────────────
  // PAGE 4: NOTIFICATIONS
  // ─────────────────────────────────────────────
  Widget _buildNotificationsPage() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(
          child: Text('Please login', style: TextStyle(color: Colors.white38)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          // FIX: Removed orderBy — needs composite index. Sorting in-memory.
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        }
        if (snap.hasError) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline,
                  size: 50, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Error loading notifications',
                  style: TextStyle(color: Colors.white38)),
            ]),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_none,
                      size: 70, color: Colors.white24),
                  SizedBox(height: 14),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                  SizedBox(height: 6),
                  Text("You'll see guide/rider/hotel responses here",
                      style: TextStyle(color: Colors.white24, fontSize: 12)),
                ]),
          );
        }
        // FIX: Sort in-memory since orderBy removed
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });
        return Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final batch = FirebaseFirestore.instance.batch();
                for (final d in docs) {
                  if (d['isRead'] != true) {
                    batch.update(d.reference, {'isRead': true});
                  }
                }
                await batch.commit();
              },
              icon: const Icon(Icons.done_all,
                  color: Colors.tealAccent, size: 16),
              label: const Text('Mark all read',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final docRef = docs[i].reference;
                final bool isRead = d['isRead'] == true;
                final String type = d['type'] ?? 'info';
                final Timestamp? ts = d['createdAt'] as Timestamp?;
                final String timeStr =
                    ts != null ? _notifTime(ts.toDate()) : '';

                return Dismissible(
                  key: Key(docs[i].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent.withOpacity(0.8),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => docRef.delete(),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    tileColor: isRead
                        ? Colors.transparent
                        : Colors.tealAccent.withOpacity(0.05),
                    leading: CircleAvatar(
                      backgroundColor: _notifIconColor(type),
                      child:
                          Icon(_notifIcon(type), color: Colors.white, size: 18),
                    ),
                    title: Text(
                      d['title'] ?? 'Notification',
                      style: TextStyle(
                          color: isRead ? Colors.white54 : Colors.white,
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 13),
                    ),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(d['body'] ?? d['message'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                          if ((d['packageName'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.landscape,
                                  color: Colors.tealAccent, size: 11),
                              const SizedBox(width: 4),
                              Text(d['packageName'],
                                  style: const TextStyle(
                                      color: Colors.tealAccent, fontSize: 11)),
                            ]),
                          ],
                        ]),
                    trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeStr,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white24)),
                          if (!isRead) ...[
                            const SizedBox(height: 4),
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.tealAccent,
                                    shape: BoxShape.circle)),
                          ],
                        ]),
                    onTap: () {
                      if (!isRead) docRef.update({'isRead': true});
                    },
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  String _notifTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.celebration;
      case 'role_accepted':
        return Icons.check_circle;
      case 'role_cancelled':
        return Icons.cancel;
      case 'welcome':
        return Icons.waving_hand;
      default:
        return Icons.notifications;
    }
  }

  Color _notifIconColor(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Colors.teal;
      case 'role_accepted':
        return Colors.green;
      case 'role_cancelled':
        return Colors.redAccent;
      case 'welcome':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  // ─────────────────────────────────────────────
  // PAGE 5: PROFILE
  // ─────────────────────────────────────────────
  Widget _buildProfilePage() {
    final canEdit = _isOnline;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(children: [
        const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 40, color: Colors.white)),
        const SizedBox(height: 10),
        if (!_isOnline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 14),
              SizedBox(width: 6),
              Text('Offline — View Only',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            ]),
          ),
        const SizedBox(height: 20),
        _profileField('Full Name', _nameCtrl, Icons.person, canEdit),
        const SizedBox(height: 15),
        Row(children: [
          _countryCodePicker(_selectedCountryCode, (v) {
            if (canEdit) setState(() => _selectedCountryCode = v);
          }),
          const SizedBox(width: 10),
          Expanded(
              child: _profileField('Phone', _phoneCtrl, Icons.phone, canEdit,
                  showLabel: false)),
        ]),
        const SizedBox(height: 15),
        _profileField('Country', _countryCtrl, Icons.flag, canEdit),
        const SizedBox(height: 25),
        if (canEdit)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: _saveProfile,
              child: const Text('SAVE PROFILE',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('LOG OUT',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _profileField(
      String label, TextEditingController ctrl, IconData icon, bool editable,
      {bool showLabel = true}) {
    return TextField(
      controller: ctrl,
      enabled: editable,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: showLabel ? label : null,
        hintText: showLabel ? null : label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        prefixIcon: Icon(icon,
            color: editable ? Colors.tealAccent : Colors.white24, size: 18),
        filled: true,
        fillColor: editable ? const Color(0xFF161B22) : Colors.black12,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'countryCode': _selectedCountryCode,
        'country': _countryCtrl.text.trim(),
      });
      setState(() {
        _cachedProfile['name'] = _nameCtrl.text.trim();
        _cachedProfile['phone'] = _phoneCtrl.text.trim();
        _cachedProfile['country'] = _countryCtrl.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('EMERGENCY SOS',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('Notify local services with your current location?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('CANCEL',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );
  }
}
