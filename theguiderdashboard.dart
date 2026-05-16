import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class GuiderDashboard extends StatefulWidget {
  const GuiderDashboard({super.key});
  @override
  State<GuiderDashboard> createState() => _GuiderDashboardState();
}

class _GuiderDashboardState extends State<GuiderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  String _id = '';
  Map<String, dynamic> _data = {};
  bool _available = true;
  bool _online = true;
  bool _loading = true; // FIX: track profile load state
  StreamSubscription? _connSub;

  String _orderFilter = 'all';
  DateTime? _filterDate;
  String _pkgBudget = 'All', _pkgType = 'All', _pkgLocation = 'All';
  String? _hoveredPkg;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // accent for this role
  static const Color _accent = Colors.tealAccent;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
    _load();
    _watchConn();
  }

  void _watchConn() {
    Connectivity()
        .checkConnectivity()
        .then((r) => setState(() => _online = r != ConnectivityResult.none));
    _connSub = Connectivity()
        .onConnectivityChanged
        .listen((r) => setState(() => _online = r != ConnectivityResult.none));
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('guides')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty)
      snap = await FirebaseFirestore.instance
          .collection('guides')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();
    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _id = snap.docs.first.id;
        _data = d;
        _available = d['isAvailable'] ?? true;
        _nameCtrl.text = d['name'] ?? '';
        _phoneCtrl.text = d['phone'] ?? '';
        _emailCtrl.text = d['email'] ?? user.email ?? '';
        _loading = false; // FIX: profile loaded
      });
    } else {
      setState(() => _loading = false); // FIX: not found, stop loading
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    _connSub?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─── SCAFFOLD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _appBar(),
      body: Column(children: [
        _tabBar(),
        Expanded(
            child: TabBarView(controller: _tc, children: [
          _dashTab(),
          _ordersTab(),
          _packagesTab(),
          _profileTab(),
        ])),
      ]),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white54, size: 18),
                onPressed: () => Navigator.pop(context))
            : null,
        title: Row(children: [
          _rolePill('GUIDE', _accent),
          const SizedBox(width: 10),
          Flexible(
              child: Text(_data['name'] ?? 'Guide Portal',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          Icon(_online ? Icons.wifi : Icons.wifi_off,
              color: _online ? _accent : Colors.redAccent, size: 15),
          const SizedBox(width: 2),
          if (_id.isNotEmpty)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('toId', isEqualTo: _id)
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (_, s) {
                final n = s.data?.docs.length ?? 0;
                return Stack(children: [
                  IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: _accent),
                      onPressed: () => _tc.animateTo(0)),
                  if (n > 0)
                    Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text('$n',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        )),
                ]);
              },
            ),
          IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: Colors.white38, size: 18),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(context).pushReplacementNamed('/');
              }),
          const SizedBox(width: 4),
        ],
      );

  Widget _tabBar() => Container(
        decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06)))),
        child: TabBar(
          controller: _tc,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          tabs: const [
            Tab(
                icon: Icon(Icons.dashboard_rounded, size: 17),
                text: 'DASHBOARD'),
            Tab(
                icon: Icon(Icons.assignment_turned_in_outlined, size: 17),
                text: 'ORDERS'),
            Tab(
                icon: Icon(Icons.card_travel_rounded, size: 17),
                text: 'PACKAGES'),
            Tab(
                icon: Icon(Icons.manage_accounts_rounded, size: 17),
                text: 'PROFILE'),
          ],
        ),
      );

  // ═══════════════════════════════════════════════
  //  TAB 0 — DASHBOARD
  // ═══════════════════════════════════════════════
  Widget _dashTab() => ListView(padding: const EdgeInsets.all(16), children: [
        _identityCard(),
        const SizedBox(height: 20),
        _secHeader('NOTIFICATIONS',
            trailing: TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: _accent, fontSize: 11)),
            )),
        const SizedBox(height: 8),
        _notifList(),
      ]);

  Widget _identityCard() {
    final langs = (_data['languages'] as List?)?.cast<String>() ?? ['English'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.withOpacity(0.22), const Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withOpacity(0.18)),
      ),
      child: Row(children: [
        _avatarCircle(Icons.person_pin_rounded, _accent),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _rolePill('CERTIFIED GUIDE', _accent),
          const SizedBox(height: 6),
          Text(_data['name'] ?? 'Guide',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
              spacing: 5,
              children: langs
                  .map((l) =>
                      _pill(l, Colors.white.withOpacity(0.07), Colors.white70))
                  .toList()),
        ])),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Switch(
              value: _available,
              activeColor: _accent,
              onChanged: (v) async {
                setState(() => _available = v);
                if (_id.isNotEmpty)
                  await FirebaseFirestore.instance
                      .collection('guides')
                      .doc(_id)
                      .update({'isAvailable': v});
              }),
          Text(_available ? 'FREE' : 'BUSY',
              style: TextStyle(
                  color: _available ? _accent : Colors.orangeAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _notifList() {
    // FIX: Show loading only while profile is being fetched, not forever
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: _accent));
    if (_id.isEmpty)
      return _empty(Icons.notifications_off_outlined,
          'Profile not found. Please re-login.');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toId', isEqualTo: _id)
          // FIX: Removed .orderBy('createdAt') — requires composite Firestore index.
          // Sorting in-memory below avoids the index requirement.
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError)
          return _empty(Icons.error_outline, 'Error loading notifications');
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator(color: _accent));
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });
        if (docs.isEmpty)
          return _empty(
              Icons.notifications_off_outlined, 'No notifications yet');
        return Column(children: docs.map(_notifTile).toList());
      },
    );
  }

  Widget _notifTile(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final read = d['read'] == true;
    final cancel = d['type'] == 'cancellation';
    return GestureDetector(
      onTap: () => _openNotif(doc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: read ? const Color(0xFF161B22) : _accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: read ? Colors.white10 : _accent.withOpacity(0.28)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: cancel
                    ? Colors.redAccent.withOpacity(0.12)
                    : _accent.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(
                cancel ? Icons.cancel_outlined : Icons.book_online_outlined,
                color: cancel ? Colors.redAccent : _accent,
                size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(d['touristName'] ?? '—',
                          style: TextStyle(
                              color: read ? Colors.white54 : Colors.white,
                              fontWeight:
                                  read ? FontWeight.normal : FontWeight.bold,
                              fontSize: 13))),
                  Text(d['packageName'] ?? '',
                      style: TextStyle(
                          color: cancel ? Colors.redAccent : _accent,
                          fontSize: 11)),
                ]),
                const SizedBox(height: 3),
                Text(_fmt(d['travelDate']),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
          if (!read)
            Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                    color: _accent, shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  void _openNotif(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final cancel = d['type'] == 'cancellation';
    final bookingId = d['bookingId'] as String?;
    doc.reference.update({'read': true});

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                    cancel
                        ? Icons.cancel_outlined
                        : Icons.notifications_active_outlined,
                    color: cancel ? Colors.redAccent : _accent,
                    size: 20),
                const SizedBox(width: 10),
                Flexible(
                    child: Text(
                        cancel ? 'BOOKING CANCELLED' : 'NEW BOOKING REQUEST',
                        style: TextStyle(
                            color: cancel ? Colors.redAccent : _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.8))),
              ]),
              const SizedBox(height: 18),
              _dRow(Icons.person, 'Tourist', d['touristName'] ?? '—'),
              _dRow(Icons.card_travel_rounded, 'Package',
                  d['packageName'] ?? '—'),
              _dRow(Icons.calendar_today, 'Travel Date', _fmt(d['travelDate'])),
              _dRow(
                  Icons.phone, 'Phone', d['touristPhone'] ?? d['phone'] ?? '—'),
              const SizedBox(height: 20),
              if (!cancel && bookingId != null)
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () async {
                      await _respond(bookingId, 'guide', 'cancelled');
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    icon: const Icon(Icons.block,
                        color: Colors.orangeAccent, size: 15),
                    label: const Text('NOT AVAILABLE',
                        style: TextStyle(
                            color: Colors.orangeAccent, fontSize: 12)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton.icon(
                    onPressed: () async {
                      await _respond(bookingId, 'guide', 'accepted');
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.black, size: 15),
                    label: const Text('ACCEPT',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  )),
                ]),
              if (cancel)
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C2128),
                            padding: const EdgeInsets.symmetric(vertical: 13)),
                        child: const Text('CLOSE',
                            style: TextStyle(color: Colors.white54)))),
            ]),
      ),
    );
  }

  Future<void> _respond(String bId, String role, String status) async {
    final ref = FirebaseFirestore.instance.collection('bookings').doc(bId);
    await ref.update({'${role}RequestStatus': status});
    final snap = await ref.get();
    if (snap.exists) {
      final d = snap.data()!;
      final bool allAccepted = d['guideRequestStatus'] == 'accepted' &&
          d['riderRequestStatus'] == 'accepted' &&
          d['hotelRequestStatus'] == 'accepted';
      if (allAccepted) {
        await ref.update({'status': 'confirmed'});
      }
      // Tourist-க்கு notification அனுப்பு
      final touristId = d['userId'] as String?;
      if (touristId != null && touristId.isNotEmpty) {
        final guideName = _data['name'] ?? 'Guide';
        final packageName = (d['packageName'] ?? '') as String;
        final travelDate = d['travelDate'];
        final String title;
        final String body;
        final String notifType;
        if (status == 'accepted') {
          if (allAccepted) {
            title = '\u{1F389} Booking Fully Confirmed!';
            body =
                'Your booking for $packageName has been confirmed by all parties. Have a great trip!';
            notifType = 'booking_confirmed';
          } else {
            title = '\u2705 Guide Accepted';
            body =
                'Guide $guideName has accepted your booking for $packageName.';
            notifType = 'role_accepted';
          }
        } else {
          title = '\u274C Guide Not Available';
          body =
              'Guide $guideName is not available for your $packageName booking. Please rebook with another guide.';
          notifType = 'role_cancelled';
        }
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': touristId,
          'toId': touristId,
          'toRole': 'tourist',
          'bookingId': bId,
          'packageName': packageName,
          'travelDate': travelDate,
          'title': title,
          'body': body,
          'message': body,
          'type': notifType,
          'isRead': false,
          'read': false,
          'createdAt': Timestamp.now(),
        });
      }
    }
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted'
              ? 'Booking accepted!'
              : 'Marked not available'),
          backgroundColor:
              status == 'accepted' ? Colors.green : Colors.orangeAccent));
  }

  Future<void> _markAllRead() async {
    if (_id.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toId', isEqualTo: _id)
        .where('read', isEqualTo: false)
        .get(); // FIX: no orderBy needed here
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.update(d.reference, {'read': true});
    await batch.commit();
  }

  // ═══════════════════════════════════════════════
  //  TAB 1 — ORDERS
  // ═══════════════════════════════════════════════
  Widget _ordersTab() => Column(children: [
        _ordFilterBar(),
        Expanded(child: _ordersList()),
      ]);

  Widget _ordFilterBar() => Container(
        color: const Color(0xFF0D1117),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          _chip2('All', _orderFilter == 'all',
              () => setState(() => _orderFilter = 'all')),
          const SizedBox(width: 8),
          _chip2('Upcoming', _orderFilter == 'upcoming',
              () => setState(() => _orderFilter = 'upcoming')),
          const SizedBox(width: 8),
          _chip2('Past', _orderFilter == 'past',
              () => setState(() => _orderFilter = 'past')),
          const Spacer(),
          _datePicker(),
        ]),
      );

  Widget _datePicker() => GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final p = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now.subtract(const Duration(days: 365)),
            lastDate: now.add(const Duration(days: 365)),
            builder: (c, child) => Theme(
                data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: _accent)),
                child: child!),
          );
          setState(() => _filterDate = p);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: _filterDate != null
                  ? _accent.withOpacity(0.14)
                  : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _filterDate != null ? _accent : Colors.white10)),
          child: Row(children: [
            Icon(Icons.calendar_today,
                color: _filterDate != null ? _accent : Colors.white38,
                size: 13),
            const SizedBox(width: 5),
            Text(
                _filterDate != null
                    ? DateFormat('MMM dd').format(_filterDate!)
                    : 'Date',
                style: TextStyle(
                    color: _filterDate != null ? _accent : Colors.white38,
                    fontSize: 11)),
            if (_filterDate != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                  onTap: () => setState(() => _filterDate = null),
                  child:
                      const Icon(Icons.close, color: Colors.white38, size: 11)),
            ]
          ]),
        ),
      );

  Widget _ordersList() {
    // FIX: use _loading to avoid forever-spinner when _id not yet fetched
    if (_loading)
      return const Center(child: CircularProgressIndicator(color: _accent));
    if (_id.isEmpty)
      return _empty(
          Icons.person_off_outlined, 'Profile not found. Please re-login.');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('guideId', isEqualTo: _id)
          // FIX: removed .where('guideRequestStatus','accepted') + .orderBy('travelDate')
          // Both together need a composite Firestore index → causes loading forever.
          // Filtering & sorting done in-memory below.
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError)
          return _empty(Icons.error_outline,
              'Error loading orders. Check Firestore rules.');
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator(color: _accent));
        final now = DateTime.now();
        // In-memory filter: only accepted + date filters
        final docs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          // Only show bookings where guide has accepted
          if ((d['guideRequestStatus'] ?? 'pending') != 'accepted')
            return false;
          final date = _toDate(d['travelDate']);
          if (date == null) return true;
          if (_filterDate != null) return _sameDay(date, _filterDate!);
          if (_orderFilter == 'upcoming') return !date.isBefore(_dayStart(now));
          if (_orderFilter == 'past') return date.isBefore(_dayStart(now));
          return true;
        }).toList()
          // Sort by travelDate ascending
          ..sort((a, b) {
            final ad = _toDate((a.data() as Map)['travelDate']);
            final bd = _toDate((b.data() as Map)['travelDate']);
            if (ad == null || bd == null) return 0;
            return ad.compareTo(bd);
          });

        if (docs.isEmpty)
          return _empty(Icons.assignment_outlined, 'No orders found');

        return ListView(
          padding: const EdgeInsets.all(14),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final date = _toDate(d['travelDate']);
            final past = date != null && date.isBefore(_dayStart(now));
            return _orderCard(d, past);
          }).toList(),
        );
      },
    );
  }

  Widget _orderCard(Map<String, dynamic> d, bool past) {
    final tag = past ? 'FINISHED' : 'UPCOMING';
    final tagC = past ? Colors.white24 : _accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: past ? const Color(0xFF111518) : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: past ? Colors.white10 : _accent.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: _accent,
        collapsedIconColor: Colors.white38,
        title: Row(children: [
          Expanded(
              child: Text(d['packageName'] ?? '',
                  style: TextStyle(
                      color: past ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))),
          _smallBadge(tag, tagC),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(Icons.calendar_today, size: 11, color: tagC),
            const SizedBox(width: 4),
            Text(_fmt(d['travelDate']),
                style: TextStyle(color: tagC, fontSize: 11)),
            const SizedBox(width: 12),
            const Icon(Icons.person, size: 11, color: Colors.white38),
            const SizedBox(width: 4),
            Flexible(
                child: Text(d['touristName'] ?? '',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11))),
          ]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: _detTable([
              ['Tourist', d['touristName'] ?? '—'],
              ['Country', d['visitorCountry'] ?? '—'],
              ['Phone', d['phone'] ?? '—'],
              ['Package', d['packageName'] ?? '—'],
              ['Travel Date', _fmt(d['travelDate'])],
              ['Rider', d['riderName'] ?? '—'],
              ['Hotel', d['hotelName'] ?? '—'],
              ['Status', (d['status'] ?? 'pending').toString().toUpperCase()],
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 2 — PACKAGES
  // ═══════════════════════════════════════════════
  Widget _packagesTab() => Column(children: [
        _pkgFilterBar(),
        Expanded(child: _pkgList()),
      ]);

  Widget _pkgFilterBar() => Container(
        color: const Color(0xFF0D1117),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Expanded(
              child: _dd(
                  'Budget',
                  _pkgBudget,
                  [
                    'All',
                    'budget Rs20000-30000',
                    'mediumRs50000-80000',
                    'premiumRs100000-200000'
                  ],
                  (v) => setState(() => _pkgBudget = v!))),
          const SizedBox(width: 8),
          Expanded(
              child: _dd(
                  'Type',
                  _pkgType,
                  ['All', 'adventure', 'beach', 'cultural', 'nature'],
                  (v) => setState(() => _pkgType = v!))),
          const SizedBox(width: 8),
          Expanded(
              child: _dd(
                  'Location',
                  _pkgLocation,
                  [
                    'All',
                    'Colombo',
                    'Kandy',
                    'Galle',
                    'Jaffna',
                    'Nuwara Eliya',
                    'Trincomalee',
                    'Matara',
                    'Hambantota',
                    'Anuradhapura'
                  ],
                  (v) => setState(() => _pkgLocation = v!))),
        ]),
      );

  Widget _pkgList() {
    Query q = FirebaseFirestore.instance.collection('packages');
    if (_pkgBudget != 'All') q = q.where('budget', isEqualTo: _pkgBudget);
    if (_pkgType != 'All') q = q.where('type', isEqualTo: _pkgType);
    if (_pkgLocation != 'All') q = q.where('location', isEqualTo: _pkgLocation);
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator(color: _accent));
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return _empty(Icons.card_travel_rounded, 'No packages found');
        return ListView(
          padding: const EdgeInsets.all(14),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final hov = _hoveredPkg == doc.id;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredPkg = doc.id),
              onExit: (_) => setState(() => _hoveredPkg = null),
              child: AnimatedScale(
                scale: hov ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: _pkgCard(d, doc.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _pkgCard(Map<String, dynamic> d, String id) {
    final typeColors = {
      'adventure': Colors.orange,
      'beach': Colors.blue,
      'cultural': Colors.purple,
      'nature': Colors.green,
    };
    final tc = typeColors[(d['type'] ?? '').toLowerCase()] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: _accent,
        collapsedIconColor: Colors.white38,
        title: Text(d['name'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Row(children: [
          const Icon(Icons.location_on, color: _accent, size: 11),
          const SizedBox(width: 4),
          Text(d['location'] ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(width: 8),
          _smallBadge(d['type'] ?? '', tc),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((d['description'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(d['description'].toString(),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12, height: 1.5)),
                ),
              _detTable([
                ['Budget', _fmtBudget(d['budget'] ?? '')],
                ['Duration', d['duration'] ?? '—'],
                ['Type', d['type'] ?? '—'],
                ['Location', d['location'] ?? '—'],
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TAB 3 — PROFILE
  // ═══════════════════════════════════════════════
  Widget _profileTab() {
    final langs = (_data['languages'] as List?)?.cast<String>() ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        _avatarCircle(Icons.person_pin_rounded, _accent,
            size: 82, iconSize: 40),
        const SizedBox(height: 8),
        _rolePill('CERTIFIED GUIDE', _accent),
        if (!_online) ...[const SizedBox(height: 8), _offlineBadge()],
        const SizedBox(height: 22),
        _field('Full Name', _nameCtrl, Icons.person, _online),
        const SizedBox(height: 12),
        _field('Phone', _phoneCtrl, Icons.phone, _online),
        const SizedBox(height: 12),
        _field('Email', _emailCtrl, Icons.email, false),
        if (langs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('LANGUAGES',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10, letterSpacing: 1))),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              children: langs
                  .map((l) => _pill(l, _accent.withOpacity(0.1), _accent))
                  .toList()),
        ],
        const SizedBox(height: 28),
        if (_online) _btn('SAVE PROFILE', _accent, Colors.black, _saveProfile),
        const SizedBox(height: 12),
        _outlineBtn('LOG OUT', Colors.redAccent, () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.of(context).pushReplacementNamed('/');
        }),
      ]),
    );
  }

  Future<void> _saveProfile() async {
    if (_id.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('guides').doc(_id).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  // ═══════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════
  Widget _secHeader(String t, {Widget? trailing}) => Row(children: [
        Text(t,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        const Spacer(),
        if (trailing != null) trailing,
      ]);

  Widget _detTable(List<List<String>> rows) => Container(
        decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10)),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  border: i < rows.length - 1
                      ? const Border(bottom: BorderSide(color: Colors.white10))
                      : null),
              child: Row(children: [
                Text(r[0],
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                const Spacer(),
                Flexible(
                    child: Text(r[1],
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end)),
              ]),
            );
          }).toList(),
        ),
      );

  Widget _dRow(IconData icon, String lbl, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, color: Colors.white38, size: 15),
          const SizedBox(width: 10),
          Text('$lbl  ',
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Expanded(
              child: Text(val,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _chip2(String lbl, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: sel ? _accent.withOpacity(0.14) : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? _accent : Colors.white10)),
          child: Text(lbl,
              style: TextStyle(
                  color: sel ? _accent : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      );

  Widget _smallBadge(String lbl, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
        child: Text(lbl,
            style:
                TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
      );

  Widget _pill(String lbl, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(lbl, style: TextStyle(color: fg, fontSize: 10)),
      );

  Widget _rolePill(String lbl, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(lbl,
            style: TextStyle(
                color: c,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _avatarCircle(IconData icon, Color c,
          {double size = 58, double iconSize = 28}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: c.withOpacity(0.35), width: 2)),
        child: Icon(icon, color: c, size: iconSize),
      );

  Widget _offlineBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 13),
          SizedBox(width: 6),
          Text('Offline — View Only',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
        ]),
      );

  Widget _field(String lbl, TextEditingController ctrl, IconData icon,
          bool editable) =>
      TextField(
        controller: ctrl,
        enabled: editable,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: lbl,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          prefixIcon:
              Icon(icon, color: editable ? _accent : Colors.white24, size: 18),
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
              borderSide: const BorderSide(color: _accent)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10)),
        ),
      );

  Widget _btn(String lbl, Color bg, Color fg, VoidCallback fn) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: fn,
          style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Text(lbl,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _outlineBtn(String lbl, Color c, VoidCallback fn) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: fn,
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: c),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Text(lbl,
              style: TextStyle(color: c, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _dd(
          String hint, String val, List<String> items, Function(String?) fn) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            dropdownColor: const Color(0xFF1C2128),
            style: const TextStyle(color: Colors.white, fontSize: 11),
            icon: const Icon(Icons.arrow_drop_down, color: _accent, size: 16),
            items: items
                .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(_short(i),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: fn,
          ),
        ),
      );

  Widget _empty(IconData icon, String msg) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
      );

  // ─── util ───
  String _fmt(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) return DateFormat('MMM dd, yyyy').format(ts.toDate());
    return ts.toString();
  }

  DateTime? _toDate(dynamic ts) => ts is Timestamp ? ts.toDate() : null;

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _short(String s) {
    if (s.contains('budget')) return 'Budget';
    if (s.contains('medium')) return 'Medium';
    if (s.contains('premium')) return 'Premium';
    return s;
  }

  String _fmtBudget(String b) {
    if (b.contains('budget')) return 'LKR 20k–30k';
    if (b.contains('medium')) return 'LKR 50k–80k';
    if (b.contains('premium')) return 'LKR 100k+';
    return b;
  }
}
