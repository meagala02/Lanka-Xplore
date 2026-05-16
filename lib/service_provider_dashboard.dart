import 'package:flutter/material.dart';

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() =>
      _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Solid Deep Theme
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "PROVIDER PORTAL",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      body: Stack(
        children: [
          // Theme-consistent background (Low opacity for clarity)
          Opacity(
            opacity: 0.3,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    "https://images.unsplash.com/photo-1546708973-b339540b5162?w=1200",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildOverviewTab(),
                _buildRequestsTab(),
                _buildInventoryTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: BUSINESS OVERVIEW ---
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Business Performance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildStatCard("Active Bookings", "14", Colors.tealAccent),
            const SizedBox(width: 15),
            _buildStatCard("Pending Invites", "03", Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 25),
        _buildSectionHeader("Recent Activity"),
        _buildActivityLog(
          "Booking confirmed for 'Blue Water Hotel'",
          "2 mins ago",
        ),
        _buildActivityLog(
          "New request from 'Nirupkanth' for Safari",
          "1 hour ago",
        ),
        _buildActivityLog("Payment received for Booking #9921", "Yesterday"),
      ],
    );
  }

  // --- TAB 2: REQUEST MANAGEMENT (Approve/Reject) ---
  Widget _buildRequestsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("Incoming Tourist Requests"),
        _buildRequestCard(
          "Praveenth Kumar",
          "Southern Coast Tour",
          "Mar 25 - Mar 30",
        ),
        _buildRequestCard("Jessica Smith", "Sigiriya Day Trip", "April 02"),
      ],
    );
  }

  // --- TAB 3: INVENTORY MANAGEMENT ---
  Widget _buildInventoryTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.tealAccent.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("My Listed Services"),
          _buildServiceItem(
            "Grand Hotel Nuwara Eliya",
            "Hotel • Premium",
            Icons.hotel,
          ),
          _buildServiceItem(
            "Coastal Express Transport",
            "Transport • Van",
            Icons.directions_bus,
          ),
          _buildServiceItem(
            "Yala Safari Experience",
            "Activity • Jeep",
            Icons.terrain,
          ),
        ],
      ),
    );
  }

  // --- TAB 4: PROFILE SETTINGS ---
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(25),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white12,
            child: Icon(
              Icons.business_center_rounded,
              size: 50,
              color: Colors.tealAccent,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildReadOnlyField("Business Name", "Lanka Travels PVT"),
        _buildReadOnlyField("Registration ID", "SL-TRV-8821"),
        _buildReadOnlyField("Contact Email", "provider@lankaxplore.com"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade900,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "EDIT BUSINESS INFO",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF161B22),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.tealAccent,
      unselectedItemColor: Colors.white30,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_rounded),
          label: "Overview",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions_rounded),
          label: "Requests",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: "Services",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: "Settings",
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(String name, String service, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            "$service • $date",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Approve"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String title, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.tealAccent),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        trailing: const Icon(Icons.edit_note_rounded, color: Colors.white24),
      ),
    );
  }

  Widget _buildActivityLog(String msg, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.tealAccent),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }
}
