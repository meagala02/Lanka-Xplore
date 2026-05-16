import 'package:flutter/material.dart';
import 'budget_packages_page.dart';
import 'medium_packages_page.dart';
import 'premium_packages_page.dart';
import 'auth_page.dart';
import 'tourist_dashboard.dart';
import 'thehoteldashboard.dart';
import 'TheRiderDashboard.dart';
import 'theguiderdashboard.dart';
import 'admin_dashboard.dart';

class VisitorHomePage extends StatefulWidget {
  final bool isLoggedIn;
  final String userRole;
  const VisitorHomePage(
      {super.key, this.isLoggedIn = false, this.userRole = "tourist"});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  final ScrollController _scrollController = ScrollController();
  late bool _isUserLoggedIn;

  @override
  void initState() {
    super.initState();
    _isUserLoggedIn = widget.isLoggedIn;
  }

  void _scrollTo(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _goToDashboard() {
    Widget target;
    switch (widget.userRole) {
      case "admin":
        target = const AdminDashboard();
        break;
      case "hotel":
        target = const HotelDashboard();
        break;
      case "rider":
        target = const RiderDashboard();
        break;
      case "guide":
        target = const GuiderDashboard();
        break;
      default:
        target = const TouristDashboard();
    }
    Navigator.push(context, MaterialPageRoute(builder: (c) => target));
  }

  void _handleLogout() {
    setState(() {
      _isUserLoggedIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }

  void _showMissionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("OUR MISSION",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    const Text(
                      "At Lanka Xplore, our mission is to redefine the Sri Lankan travel experience through technology. We aim to empower local service providers while offering global travelers a safe, transparent, and deeply authentic journey through the 'Pearl of the Indian Ocean'. We believe in sustainable tourism that respects nature and elevates local heritage.",
                      style: TextStyle(
                          fontSize: 18, height: 1.8, color: Colors.black87),
                    ),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 40),
                    const Text("COMPANY SUCCESS & RATINGS",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    _buildMissionStat("Overall User Rating", "4.9 / 5.0",
                        Icons.star, Colors.amber),
                    _successProgressBar("Service Quality", 0.98),
                    _successProgressBar("Safety Standards", 1.0),
                    _successProgressBar("Customer Satisfaction", 0.95),
                    const SizedBox(height: 40),
                    const Text("LATEST REVIEWS",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildReviewCard(
                        "John Doe",
                        "The best travel management app I've used in Sri Lanka. The travel experience was flawless!",
                        5),
                    _buildReviewCard(
                        "Sarah Williams",
                        "Authentic experiences that felt safe and well-curated. Highly recommended!",
                        5),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20)),
                        child: const Text("CLOSE DETAILS",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionStat(
      String title, String val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(val,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }

  Widget _successProgressBar(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: val,
              backgroundColor: Colors.grey[200],
              color: Colors.teal,
              minHeight: 8),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String review, int stars) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: List.generate(
                  stars,
                  (index) =>
                      const Icon(Icons.star, color: Colors.amber, size: 16))),
          const SizedBox(height: 10),
          Text("\"$review\"",
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.black54)),
          const SizedBox(height: 10),
          Text("- $name",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.travel_explore, color: Colors.teal, size: 35),
            SizedBox(width: 10),
            Text(
              "LANKA XPLORE",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          _navButton("About Us", () => _scrollTo(700)),
          _navButton("Services", () => _scrollTo(1300)),
          _navButton("Destinations", () => _scrollTo(1850)),
          _navButton("Packages", () => _scrollTo(2600)),
          const SizedBox(width: 10),
          if (_isUserLoggedIn) ...[
            _navButton("DASHBOARD", _goToDashboard),
            _navButton("LOGOUT", _handleLogout),
          ],
          const SizedBox(width: 10),
          if (!_isUserLoggedIn) _loginButton(),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildSection(
              title: "ABOUT US",
              subtitle: "Your Trusted Partner in Sri Lankan Travel",
              child: _buildAboutSection(),
            ),
            _buildSection(
              title: "OUR SERVICES",
              subtitle: "Everything you need for a perfect journey",
              backgroundColor: Colors.grey.shade50,
              child: _buildServicesGrid(),
            ),
            _buildSection(
              title: "POPULAR DESTINATIONS",
              subtitle: "Explore the most loved spots in the island",
              child: _buildDestinationGrid(),
            ),
            _buildSection(
              title: "TRAVEL PACKAGES",
              subtitle: "Find a plan that fits your lifestyle",
              backgroundColor: Colors.grey.shade900,
              darkTheme: true,
              child: _buildPackageTiers(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    Color backgroundColor = Colors.white,
    bool darkTheme = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      color: backgroundColor,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkTheme ? Colors.white : Colors.black,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: darkTheme ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(height: 60),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 750,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/sl.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.4),
        ),
      ),
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.3)),
          Padding(
            padding: const EdgeInsets.only(top: 450),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "AYUBOWAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "EXPERIENCE THE PEARL OF THE INDIAN OCEAN",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 10,
                            color: Colors.black45,
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Founded in 2026, Lanka Xplore is a smart management system designed to bridge the gap between local service providers and global travelers. We ensure safety, quality, and authenticity in every mile you travel.",
                style:
                    TextStyle(fontSize: 18, height: 1.8, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              OutlinedButton(
                onPressed: () => _showMissionDetails(context),
                style:
                    OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
                child: const Text("LEARN MORE ABOUT OUR MISSION"),
              ),
            ],
          ),
        ),
        const SizedBox(width: 50),
        Expanded(
          child: Row(
            children: [
              _aboutImage('assets/ella.jpg'),
              const SizedBox(width: 15),
              _aboutImage('assets/kandy.jpg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutImage(String path) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(path, height: 350, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Wrap(
      spacing: 40,
      runSpacing: 40,
      alignment: WrapAlignment.center,
      children: [
        _serviceCard(
            Icons.hotel_class, "Premium Stays", "Curated hotels and villas."),
        _serviceCard(Icons.map_rounded, "Expert Guides",
            "Local knowledge you won't find in books."),
        _serviceCard(Icons.support_agent, "24/7 Support",
            "We are with you every step of the way."),
      ],
    );
  }

  Widget _serviceCard(IconData icon, String title, String desc) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal, size: 50),
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDestinationGrid() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        _destTile("Ella", 'assets/ella.jpg'),
        _destTile("Galle", 'assets/galle.jpg'),
        _destTile("Kandy", 'assets/kandy.jpg'),
        _destTile("Sigiriya", 'assets/sigiriya.jpg'),
      ],
    );
  }

  Widget _destTile(String name, String img) {
    bool isHovered = false;

    return StatefulBuilder(builder: (context, setState) {
      return MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          width: 300,
          height: 400,
          transform: isHovered
              ? (Matrix4.identity()
                ..scale(1.05)
                ..translate(-5.0, -10.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? Colors.black.withOpacity(0.25)
                    : Colors.transparent,
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(img, fit: BoxFit.cover)),
                Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black, Colors.transparent]))),
                Positioned(
                    bottom: 30,
                    left: 30,
                    child: Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPackageTiers() {
    return Row(
      children: [
        _packageCard(
            "BUDGET",
            Colors.teal,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const BudgetPackagesPage()))),
        const SizedBox(width: 20),
        _packageCard(
            "MEDIUM",
            Colors.orange,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const MediumPackagesPage()))),
        const SizedBox(width: 20),
        _packageCard(
            "PREMIUM",
            Colors.purple,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const PremiumPackagesPage()))),
      ],
    );
  }

  Widget _packageCard(String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_travel, color: color, size: 60),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
              child: const Text("EXPLORE",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onTap) {
    return TextButton(
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)));
  }

  Widget _loginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (c) => const AuthPage())),
      child: const Text("LOGIN / JOIN", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("LANKA XPLORE",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3)),
                    const SizedBox(height: 20),
                    Text(
                      "Redefining Sri Lankan travel with smart, secure, and authentic management systems. We connect travelers with the heart of the island.",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), height: 1.6),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _footerColumn("Quick Links", [
                "About Us",
                "Destinations",
                "Travel Packages",
                "Terms of Service"
              ]),
              const SizedBox(width: 50),
              _footerColumn("Contact Us", [
                "Negombo, Sri Lanka",
                "+94 11 234 5678",
                "info@lankaxplore.lk",
                "Support: 24/7"
              ]),
            ],
          ),
          const SizedBox(height: 80),
          const Divider(color: Colors.white24),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                  "© 2026 Lanka Xplore - Smart Tourist Management System",
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Row(
                children: [
                  _socialIcon(Icons.facebook),
                  const SizedBox(width: 15),
                  _socialIcon(Icons.camera_alt),
                  const SizedBox(width: 15),
                  _socialIcon(Icons.alternate_email),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 20),
        ...items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(item,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ))
            .toList(),
      ],
    );
  }

  Widget _socialIcon(IconData icon) {
    return Icon(icon, color: Colors.white38, size: 20);
  }
}
