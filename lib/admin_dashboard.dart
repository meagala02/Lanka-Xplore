import 'package:flutter/material.dart';
import 'packages_tab.dart';
import 'onboard_tab.dart';
import 'services_tab.dart';
import 'feedback_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard,
                  color: Colors.tealAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "ADMIN COMMAND CENTER",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.5,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _tabLabel(_selectedIndex),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white24,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: "Packages"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1), label: "Onboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.table_chart), label: "Services"),
          BottomNavigationBarItem(
              icon: Icon(Icons.feedback_outlined),
              label: "Feedback"), // ← CHANGED
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const PackagesTab();
      case 1:
        return const OnboardTab();
      case 2:
        return const ServicesTab();
      case 3:
        return const FeedbackTab(); // ← CHANGED (was "Coming Soon")
      default:
        return const PackagesTab();
    }
  }

  Widget _tabLabel(int index) {
    final labels = ['PACKAGES', 'ONBOARD', 'SERVICES', 'FEEDBACK']; // ← CHANGED
    final colors = [
      Colors.tealAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors[index].withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[index].withOpacity(0.3)),
      ),
      child: Text(labels[index],
          style: TextStyle(
              color: colors[index],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }
}
