import 'package:flutter/material.dart';

class BudgetPackagesPage extends StatelessWidget {
  const BudgetPackagesPage({super.key});

  void _showPackageDetails(BuildContext context, Map<String, dynamic> package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              height: 250,
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
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(package['name']!,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(package['price']!,
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                        "${package['days']} Days / ${package['nights']} Nights",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16)),
                    const Divider(height: 40),
                    const Text("INCLUSIONS",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(package['includes']!,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 25),
                    const Text("PLACES YOU WILL VISIT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(package['itinerary']!,
                        style: const TextStyle(
                            color: Colors.black87, height: 1.5)),
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
    final List<Map<String, String>> budgetDeals = [
      {
        "name": "Backpacker Solo",
        "price": "LKR 15,000",
        "img":
            "https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=2070&auto=format&fit=crop",
        "days": "2",
        "nights": "1",
        "includes":
            "• Hostel accommodation\n• Public transport pass\n• Local breakfast",
        "itinerary": "Nine Arches Bridge, Little Adam's Peak, and Ravana Falls."
      },
      {
        "name": "Cultural Budget",
        "price": "LKR 22,000",
        "img":
            "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=1932&auto=format&fit=crop",
        "days": "3",
        "nights": "2",
        "includes":
            "• Guesthouse stay\n• Train tickets\n• Temple entrance fees",
        "itinerary":
            "Temple of the Tooth, Kandy Lake, and Bahirawakanda Temple."
      },
      {
        "name": "Eco Explorer",
        "price": "LKR 18,500",
        "img":
            "https://images.unsplash.com/photo-1586902197503-e71026292412?q=80&w=2072&auto=format&fit=crop",
        "days": "2",
        "nights": "1",
        "includes": "• Eco-lodge stay\n• Guided hike\n• Village lunch",
        "itinerary": "Pidurangala Rock, Sigiriya outskirts, and Minneriya Park."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text("Budget Escapes",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green.shade900,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Text("Swipe to explore budget deals",
                style: TextStyle(color: Colors.black54, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: budgetDeals.length,
              itemBuilder: (context, index) {
                bool isHovered = false;

                return StatefulBuilder(builder: (context, setState) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: GestureDetector(
                      onTap: () =>
                          _showPackageDetails(context, budgetDeals[index]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 300,
                        margin: const EdgeInsets.only(right: 20),
                        // Optimized transform to prevent web crashes
                        transform: isHovered
                            ? (Matrix4.identity()
                              ..translate(0.0, -10.0)
                              ..scale(1.02))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          // Stable shadow values
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8))
                                ]
                              : [],
                          image: DecorationImage(
                              image: NetworkImage(budgetDeals[index]['img']!),
                              fit: BoxFit.cover),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(budgetDeals[index]['name']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(budgetDeals[index]['price']!,
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
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
            padding: const EdgeInsets.all(25),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("BACK TO EXPLORE",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
