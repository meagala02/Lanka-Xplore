import 'package:flutter/material.dart';

class PremiumPackagesPage extends StatelessWidget {
  const PremiumPackagesPage({super.key});

  void _showPackageDetails(BuildContext context, Map<String, dynamic> package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                image: DecorationImage(
                    image: NetworkImage(package['img']!), fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package['name']!,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    Text(package['price']!,
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        "${package['days']} Days / ${package['nights']} Nights Luxury Experience",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16)),
                    const Divider(height: 40),
                    const Text("EXECUTIVE INCLUSIONS",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.amber)),
                    const SizedBox(height: 10),
                    Text(package['includes']!,
                        style: const TextStyle(fontSize: 16, height: 1.8)),
                    const SizedBox(height: 30),
                    const Text("VIP ITINERARY",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.amber)),
                    const SizedBox(height: 10),
                    Text(package['itinerary']!,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 15, height: 1.6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> premiumDeals = [
      {
        "name": "Royal Island Tour",
        "price": "LKR 120,000",
        "img":
            "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?q=80&w=2000&auto=format&fit=crop",
        "days": "7",
        "nights": "6",
        "includes":
            "• 5-Star Luxury Resorts\n• Luxury SUV Transport\n• All-Inclusive Dining\n• Helicopter Transfers",
        "itinerary":
            "Private tour of Sigiriya, Luxury stay in Kandy, and Private Yacht in Trincomalee."
      },
      {
        "name": "Luxury Tea Estate",
        "price": "LKR 95,000",
        "img":
            "https://images.unsplash.com/photo-1550133730-695473e544be?q=80&w=2000&auto=format&fit=crop",
        "days": "4",
        "nights": "3",
        "includes":
            "• Colonial Bungalow Stay\n• Private Butler Service\n• Tea Tasting Experience",
        "itinerary":
            "Hatton Colonial Trails, Adam's Peak via Helicopter, and High Tea at Grand Hotel."
      },
      {
        "name": "Island Paradise VIP",
        "price": "LKR 150,000",
        "img":
            "https://images.unsplash.com/photo-1506477331477-33d5d8b3dc85?q=80&w=2000&auto=format&fit=crop",
        "days": "10",
        "nights": "9",
        "includes":
            "• Beachside Presidential Suites\n• Personal Chef\n• Private Seaplane Tours",
        "itinerary":
            "Exclusive Maldives-style water villas in Bentota, Private Diving, and Spa retreats."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Elite Experiences",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.amber,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 20, 30, 10),
            child: Text("The ultimate luxury in Sri Lankan travel",
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: premiumDeals.length,
              itemBuilder: (context, index) {
                bool isHovered = false;

                return StatefulBuilder(builder: (context, setState) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: GestureDetector(
                      onTap: () =>
                          _showPackageDetails(context, premiumDeals[index]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 320,
                        margin: const EdgeInsets.only(right: 25),
                        transform: isHovered
                            ? (Matrix4.identity()
                              ..translate(0.0, -12.0)
                              ..scale(1.03))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                      color: Colors.amber.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10))
                                ]
                              : [],
                          image: DecorationImage(
                              image: NetworkImage(premiumDeals[index]['img']!),
                              fit: BoxFit.cover),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(premiumDeals[index]['name']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 5),
                              Text(premiumDeals[index]['price']!,
                                  style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("BACK TO EXPLORE",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
