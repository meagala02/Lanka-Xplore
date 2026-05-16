import 'package:flutter/material.dart';

class MediumPackagesPage extends StatelessWidget {
  const MediumPackagesPage({super.key});

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
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.blue.shade700,
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
    final List<Map<String, String>> mediumDeals = [
      {
        "name": "Coastal Comfort",
        "price": "LKR 45,000",
        "img":
            "https://images.pexels.com/photos/1007427/pexels-photo-1007427.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
        "days": "4",
        "nights": "3",
        "includes":
            "• 3-Star Hotels\n• Private Car with Driver\n• Half-board meals",
        "itinerary": "Galle Fort, Unawatuna Beach, and Mirissa Whale Watching."
      },
      {
        "name": "Hill Country Charm",
        "price": "LKR 52,000",
        // UPDATED: Fresh, high-stability link for the 2nd image
        "img":
            "https://images.pexels.com/photos/1643449/pexels-photo-1643449.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
        "days": "5",
        "nights": "4",
        "includes":
            "• Boutique Villas\n• Scenic Train Journey\n• Guided Nature Tours",
        "itinerary": "Nuwara Eliya Tea Estates, Horton Plains, and Ella Gap."
      },
      {
        "name": "Wild Safari",
        "price": "LKR 48,500",
        "img":
            "https://images.pexels.com/photos/1054666/pexels-photo-1054666.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
        "days": "3",
        "nights": "2",
        "includes":
            "• Safari Lodges\n• 4x4 Private Jeep\n• National Park Entrance",
        "itinerary": "Yala National Park, Udawalawe Elephant Transit Home."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FA),
      appBar: AppBar(
        title: const Text("Medium Comforts",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Text("Upgrade your experience with comfort",
                style: TextStyle(color: Colors.black54, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: mediumDeals.length,
              itemBuilder: (context, index) {
                bool isHovered = false;

                return StatefulBuilder(builder: (context, setState) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: GestureDetector(
                      onTap: () =>
                          _showPackageDetails(context, mediumDeals[index]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 300,
                        margin: const EdgeInsets.only(right: 20),
                        transform: isHovered
                            ? (Matrix4.identity()
                              ..translate(0.0, -10.0)
                              ..scale(1.02))
                            : Matrix4.identity(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8))
                                ]
                              : [],
                          image: DecorationImage(
                              image: NetworkImage(mediumDeals[index]['img']!),
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
                              Text(mediumDeals[index]['name']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(mediumDeals[index]['price']!,
                                  style: TextStyle(
                                      color: Colors.blue.shade200,
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
                  backgroundColor: Colors.blue.shade800,
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
