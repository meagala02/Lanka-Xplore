import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeedbackTab extends StatefulWidget {
  const FeedbackTab({super.key});

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab Bar ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.tealAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
            ),
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(
                icon: Icon(Icons.person_pin_outlined, size: 16),
                text: 'SERVICE',
              ),
              Tab(
                icon: Icon(Icons.rate_review_outlined, size: 16),
                text: 'GENERAL',
              ),
            ],
          ),
        ),

        // ── Tab Content ───────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ServiceFeedbackList(),
              _GeneralFeedbackList(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICE FEEDBACK LIST  (type == 'service')
// Shows: Guide / Rider / Hotel feedback from tourists
// ─────────────────────────────────────────────────────────────
class _ServiceFeedbackList extends StatefulWidget {
  @override
  State<_ServiceFeedbackList> createState() => _ServiceFeedbackListState();
}

class _ServiceFeedbackListState extends State<_ServiceFeedbackList> {
  String _filterType = 'all'; // 'all' | 'guide' | 'rider' | 'hotel'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'guide', 'rider', 'hotel'].map((type) {
                final isSelected = _filterType == type;
                final color = _serviceColor(type);
                return GestureDetector(
                  onTap: () => setState(() => _filterType = type),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? color.withOpacity(0.2) : Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? color : Colors.white10),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                          color: isSelected ? color : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Feedback list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filterType == 'all'
                ? FirebaseFirestore.instance
                    .collection('feedback')
                    .where('type', isEqualTo: 'service')
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('feedback')
                    .where('type', isEqualTo: 'service')
                    .where('serviceType', isEqualTo: _filterType)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent)));
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent));
              }
              // Sort by createdAt descending in Dart (no index needed)
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final at = (a.data() as Map)['createdAt'];
                  final bt = (b.data() as Map)['createdAt'];
                  if (at == null || bt == null) return 0;
                  return (bt as Timestamp).compareTo(at as Timestamp);
                });
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          color: Colors.white24, size: 48),
                      SizedBox(height: 10),
                      Text('No service feedback yet',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _ServiceFeedbackCard(data: d);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _serviceColor(String type) {
    switch (type) {
      case 'guide':
        return Colors.tealAccent;
      case 'rider':
        return Colors.blueAccent;
      case 'hotel':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }
}

class _ServiceFeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ServiceFeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final serviceType = data['serviceType'] ?? 'guide';
    final serviceName = data['serviceName'] ?? '-';
    final touristName = data['touristName'] ?? 'Tourist';
    final stars = (data['stars'] ?? 0) as int;
    final description = data['description'] ?? '';
    final createdAt = data['createdAt'];
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format((createdAt as Timestamp).toDate())
        : '-';

    final color = _typeColor(serviceType);
    final icon = _typeIcon(serviceType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        serviceType.toUpperCase(),
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tourist name
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white38, size: 13),
              const SizedBox(width: 6),
              Text(
                'By $touristName',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Comment
          if (description.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$description"',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Date
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white24, size: 11),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'guide':
        return Colors.tealAccent;
      case 'rider':
        return Colors.blueAccent;
      case 'hotel':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'guide':
        return Icons.person_pin;
      case 'rider':
        return Icons.directions_car;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.star;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// GENERAL FEEDBACK LIST  (type == 'general')
// Shows: Overall Lanka Xplore experience feedback
// ─────────────────────────────────────────────────────────────
class _GeneralFeedbackList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .where('type', isEqualTo: 'general')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        // Sort by createdAt descending in Dart (no index needed)
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined,
                    color: Colors.white24, size: 48),
                SizedBox(height: 10),
                Text('No general feedback yet',
                    style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        // Calculate average rating at top
        final totalStars = docs.fold<int>(
            0, (sum, d) => sum + ((d.data() as Map)['stars'] ?? 0) as int);
        final avgRating = totalStars / docs.length;

        return Column(
          children: [
            // Summary card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.2),
                    Colors.blueAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                      '${docs.length}', 'Total Reviews', Icons.reviews),
                  Container(width: 1, height: 40, color: Colors.white10),
                  _summaryItem(
                      avgRating.toStringAsFixed(1), 'Avg Rating', Icons.star),
                ],
              ),
            ),

            // Feedback list
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _GeneralFeedbackCard(data: d);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _GeneralFeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _GeneralFeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final touristName = data['touristName'] ?? 'Tourist';
    final stars = (data['stars'] ?? 0) as int;
    final description = data['description'] ?? '';
    final createdAt = data['createdAt'];
    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format((createdAt as Timestamp).toDate())
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF1C2952),
                child: Icon(Icons.person, color: Colors.blueAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  touristName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              // Stars
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$stars/5',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$description"',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white24, size: 11),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
