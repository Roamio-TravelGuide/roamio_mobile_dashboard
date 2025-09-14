import 'package:flutter/material.dart';
import 'package-details.dart'; // <-- Import your details page

class TravelPackage {
  final String id;
  final String title;
  final String destination;
  final double price;
  final String image;
  final bool isDownloaded;
  final String description;

  TravelPackage({
    required this.id,
    required this.title,
    required this.destination,
    required this.price,
    required this.image,
    required this.isDownloaded,
    required this.description,
  });

  TravelPackage copyWith({bool? isDownloaded}) {
    return TravelPackage(
      id: id,
      title: title,
      destination: destination,
      price: price,
      image: image,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      description: description,
    );
  }
}

class MyTrips extends StatefulWidget {
  const MyTrips({Key? key}) : super(key: key);

  @override
  State<MyTrips> createState() => _TravelPackagesScreenState();
}

class _TravelPackagesScreenState extends State<MyTrips> {
  List<TravelPackage> packages = [
    TravelPackage(
      id: "1",
      title: "Tropical Paradise Getaway",
      destination: "Maldives",
      price: 2499,
      image: "assets/images/tropical-maldives-resort.jpg",
      isDownloaded: true,
      description: "Experience luxury overwater bungalows and pristine beaches",
    ),
    TravelPackage(
      id: "2",
      title: "European Cultural Tour",
      destination: "Italy & France",
      price: 3299,
      image: "assets/images/european-cities-italy-france.jpg",
      isDownloaded: false,
      description: "Explore historic cities, art museums, and culinary delights",
    ),
    TravelPackage(
      id: "3",
      title: "Adventure Mountain Trek",
      destination: "Nepal Himalayas",
      price: 1899,
      image: "assets/images/himalayan-mountain-trek-nepal.jpg",
      isDownloaded: true,
      description: "Challenge yourself with breathtaking mountain views",
    ),
    TravelPackage(
      id: "4",
      title: "Safari Wildlife Experience",
      destination: "Kenya & Tanzania",
      price: 2799,
      image: "assets/images/african-safari-wildlife-kenya.jpg",
      isDownloaded: false,
      description: "Witness the Great Migration and Big Five animals",
    ),
  ];

  void handleDownload(String packageId) {
    setState(() {
      packages = packages.map((pkg) {
        if (pkg.id == packageId) {
          return pkg.copyWith(isDownloaded: true);
        }
        return pkg;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'My Trips',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),

              // Packages List
              Expanded(
                child: ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          // ✅ Navigate to details page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                             builder: (context) => Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        canvasColor: const Color(0xFF0D0D12), // Important
      ),
      child: const DestinationDetailsPage(),
    
                                
),
                            ),
                          );
                        },
                        child: TravelPackageCard(
                          package: package,
                          onDownload: () => handleDownload(package.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TravelPackageCard extends StatelessWidget {
  final TravelPackage package;
  final VoidCallback onDownload;

  const TravelPackageCard({
    Key? key,
    required this.package,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: package.image.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(package.image),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: package.image.isEmpty
                ? Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image, size: 60, color: Colors.grey),
                  )
                : null,
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  package.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Destination
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        package.destination,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  package.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Price + Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${package.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    package.isDownloaded
                        ? ElevatedButton.icon(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.check, size: 16, color: Colors.white),
                            label: const Text(
                              "Downloaded",
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: onDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.download, size: 16, color: Colors.white),
                            label: const Text(
                              "Download",
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
