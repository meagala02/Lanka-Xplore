import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<Map<String, dynamic>> _sections = [
    {
      'label': 'Admins',
      'collection': 'admins',
      'icon': Icons.admin_panel_settings,
      'color': Colors.redAccent,
      'idField': 'userId',
      'nameField': 'fullName',
    },
    {
      'label': 'Hotels',
      'collection': 'hotels',
      'icon': Icons.hotel,
      'color': Colors.orangeAccent,
      'idField': 'userId',
      'nameField': 'hotelName',
    },
    {
      'label': 'Riders',
      'collection': 'riders',
      'icon': Icons.two_wheeler,
      'color': Colors.blueAccent,
      'idField': 'userId',
      'nameField': 'fullName',
    },
    {
      'label': 'Guides',
      'collection': 'guides',
      'icon': Icons.tour,
      'color': Colors.greenAccent,
      'idField': 'userId',
      'nameField': 'fullName',
    },
    {
      'label': 'Tourists',
      'collection': 'users',
      'icon': Icons.person,
      'color': Colors.purpleAccent,
      'idField': 'userId',
      'nameField': 'fullName',
    },
    {
      'label': 'Bookings',
      'collection': 'bookings',
      'icon': Icons.book_online,
      'color': Colors.tealAccent,
      'idField': 'bookingId',
      'nameField': 'packageName',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section tabs
        Container(
          color: const Color(0xFF161B22),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white38,
            tabs: _sections.map((s) {
              return Tab(
                child: Row(
                  children: [
                    Icon(s['icon'] as IconData,
                        size: 15, color: s['color'] as Color),
                    const SizedBox(width: 6),
                    Text(s['label'] as String,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: _sections.map((section) {
              return _SectionView(section: section);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  final Map<String, dynamic> section;

  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final color = section['color'] as Color;
    final collection = section['collection'] as String;
    final idField = section['idField'] as String;
    final nameField = section['nameField'] as String;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Error loading ${section['label']}",
                  style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        // Sort by createdAt descending in Dart (no Firestore index needed)
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(section['icon'] as IconData,
                    color: color.withOpacity(0.3), size: 50),
                const SizedBox(height: 12),
                Text("No ${section['label']} found",
                    style: const TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1C2128),
              child: Row(
                children: [
                  Icon(section['icon'] as IconData, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(section['label'] as String,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("${docs.length} records",
                        style: TextStyle(color: color, fontSize: 11)),
                  ),
                ],
              ),
            ),

            // Data list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () => _showDetailSheet(
                        context, data, color, section['label'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2128),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              data[idField]?.toString() ?? '#',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        title: Text(
                          data[nameField]?.toString() ?? 'N/A',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        subtitle: Text(
                          _buildSubtitle(data, section['label'] as String),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.white24, size: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildSubtitle(Map<String, dynamic> data, String label) {
    switch (label) {
      case 'Admins':
        return "${data['email'] ?? ''} • ${data['phone'] ?? ''}";
      case 'Hotels':
        return "${data['email'] ?? ''} • ${data['address'] ?? ''}";
      case 'Riders':
        final vehicles = (data['vehicleTypes'] as List?)?.join(', ') ?? '';
        return "${data['phone'] ?? ''} • $vehicles";
      case 'Guides':
        final langs = (data['languages'] as List?)?.join(', ') ?? '';
        return "${data['experience'] ?? '0'} yrs exp • $langs";
      case 'Tourists':
        return "${data['email'] ?? ''} • ${data['phone'] ?? ''}";
      case 'Bookings':
        return "${data['bookingId'] ?? ''} • ${data['status'] ?? 'pending'}";
      default:
        return data['email'] ?? '';
    }
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> data,
      Color color, String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("$label Details",
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              ..._buildDetailRows(data, label, color),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailRows(
      Map<String, dynamic> data, String label, Color color) {
    // Password field exclude panrom
    final excludeFields = ['password', 'createdAt'];
    final entries =
        data.entries.where((e) => !excludeFields.contains(e.key)).toList();

    return entries.map((entry) {
      final key = entry.key;
      final value = entry.value;

      String displayValue;
      if (value is List) {
        displayValue = value.join(', ');
      } else if (value == null || value.toString().isEmpty) {
        displayValue = '-';
      } else {
        displayValue = value.toString();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                _formatKey(key),
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatKey(String key) {
    // camelCase to Title Case
    final result =
        key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}');
    return result[0].toUpperCase() + result.substring(1);
  }
}
