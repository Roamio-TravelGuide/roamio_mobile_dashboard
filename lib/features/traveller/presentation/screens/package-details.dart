import 'package:flutter/material.dart';
import './package_checkout.dart';
import 'gallery_page.dart';


void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final seed = const Color.fromARGB(255, 7, 37, 94); // Dark blue seed color
    return MaterialApp(
      title: 'Travel Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
         colorScheme: const ColorScheme.dark(
         primary: Color(0xFF0F77EE), // Exact color
    //background: Color(0xFF0A1220),
  ),
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        useMaterial3: true,
      ),
      home: const DestinationDetailsPage(),
    );
  }
}

class DestinationDetailsPage extends StatefulWidget {
  const DestinationDetailsPage({super.key});

  @override
  State<DestinationDetailsPage> createState() => _DestinationDetailsPageState();
}

class _DestinationDetailsPageState extends State<DestinationDetailsPage> {
  int _currentNav = 0;
  int? currentPlayingIndex;
  bool isPlaying = false;

  static const heroImage =
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop';

  static const tanahLotPhotos = <String>[
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1483683804023-6ccdb62f86ef?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1494475673545-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1482192505345-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // let content go behind bottom nav
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with hero image
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            expandedHeight: 280,
            elevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    cacheWidth: 800,
                    cacheHeight: 600,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
                  ),
                  const _TopToBottomShade(),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8, // below status bar
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        _CircleIconButton(
                          icon: Icons.bookmark_border,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _CircleIconButton(icon: Icons.ios_share, onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SliverPadding(
            padding: EdgeInsets.only(
              top: 16,
              bottom: 16, // space for CTA + nav
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _EllaDetailsSection(),
                ),
                const SizedBox(height: 16),

                // Gallery section
                _SectionHeader(
                  title: 'Gallery',
                  actionLabel: 'See All',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GalleryPage(
                          title: 'Gallery',
                          photos: tanahLotPhotos,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tanahLotPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _GalleryThumb(url: tanahLotPhotos[index]),
                  ),
                ),

                const SizedBox(height: 20),

                // Trip to Ella section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Trip to Ella',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AudioCard(
                          title: 'Tamil Lal Temple',
                          description:
                              'Tamil Lal Temple is one of Bali\'s most iconic landmarks, known for its stegggg ggggg hhhhhhhh',
                          image: tanahLotPhotos[index % tanahLotPhotos.length],
                          index: index,
                          onPlayAudio: () => _onPlayAudio(index),
                          isCurrentlyPlaying: currentPlayingIndex == index && isPlaying,
                        ),
                      );
                    }),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),

      // Bottom controls
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPlayingIndex != null && isPlaying)
              _BottomAudioPlayer(
                title: 'Tamil Lal Temple',
                onPlayPause: () {
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
                onStop: () {
                  setState(() {
                    currentPlayingIndex = null;
                    isPlaying = false;
                  });
                },
                isPlaying: isPlaying,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    
                  },
                  child: const Text('Start a Trip'),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.explore_outlined,
                      label: 'Explore',
                      selected: _currentNav == 0,
                      onTap: () => setState(() => _currentNav = 0),
                    ),
                    _NavItem(
                      icon: Icons.favorite_outline,
                      label: 'Saved',
                      selected: _currentNav == 1,
                      onTap: () => setState(() => _currentNav = 1),
                    ),
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Trips',
                      selected: _currentNav == 2,
                      onTap: () => setState(() => _currentNav = 2),
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      selected: _currentNav == 3,
                      onTap: () => setState(() => _currentNav = 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlayAudio(int index) {
    if (index < 2) {
      // First 2 cards - show audio player
      setState(() {
        if (currentPlayingIndex == index && isPlaying) {
          isPlaying = false;
        } else {
          currentPlayingIndex = index;
          isPlaying = true;
        }
      });
    } else {
      // Last 3 cards - show purchase dialog
      _showBuyTourDialog(context);
    }
  }
}

/* ------------------------------ Gallery Page ------------------------------- */
void _showBuyTourDialog(BuildContext context) {
  String selectedOption = 'full';

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                  // Warning icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_outlined,
                      color: Colors.amber,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title text
                  Text(
                    'Previews are limited to the first 2 locations. Buy the tour to get access to location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Options title
                  Text(
                    'Choose how you want to Buy?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Radio options
                  Column(
                    children: [
                      _RadioOption(
                        value: 'full',
                        groupValue: selectedOption,
                        title: 'Full tour',
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _RadioOption(
                        value: 'custom',
                        groupValue: selectedOption,
                        title: 'Custom tour',
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Buy Now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog first
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              tourType: selectedOption,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



/* ------------------------------ Shared Widgets ------------------------------- */

class _TopToBottomShade extends StatelessWidget {
  const _TopToBottomShade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x990A1220), // top dim
            Color(0x00000000), // center clear
            Color(0xCC0A1220), // bottom dark
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// New Ella-style details section
class _EllaDetailsSection extends StatelessWidget {
  const _EllaDetailsSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + rating + distance
        Row(
          children: [
            const Text(
              'Ella',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            const Text('4.6', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(width: 2),
            Text(
              '/5 (Reviews)',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.place, size: 12, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    '137 km',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // "Show map" row
        Row(
          children: [
            Text(
              '60 km away from you',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Show map',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Preview Tour button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, color: cs.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Preview Tour',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Description
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text:
                    'Tanah Lot Temple is one of Bali\'s most iconic for known its stunning offshore setting and beautiful sunset views. The temple is perched on a rock formation, surrounded by the sea during high tide, which makes it ',
              ),
              TextSpan(
                text: 'Read more...',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Info row
        Row(
          children: const [
            Expanded(
              child: _InfoColumn(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: 'Badulla, Uva',
              ),
            ),
            Expanded(
              child: _InfoColumn(
                icon: Icons.person_outline,
                title: 'Tour Producer',
                subtitle: 'Perera',
              ),
            ),
            Expanded(
              child: _InfoColumn(
                icon: Icons.attach_money,
                title: 'Price',
                subtitle: '\$4 - \$5 USD',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoColumn({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Audio card for the new trip section
class _AudioCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final int index;
  final VoidCallback onPlayAudio;
  final bool isCurrentlyPlaying;

  const _AudioCard({
    required this.title,
    required this.description,
    required this.image,
    required this.index,
    required this.onPlayAudio,
    required this.isCurrentlyPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 11, 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                // Buttons row
                Row(
                  children: [
                    _ActionButton(
                      icon: isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      label: 'Play audio',
                      onTap: onPlayAudio,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.directions,
                      label: 'Show directions',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description with read more
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: description),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'Read more...',
                        style: TextStyle(
                          color: const Color.fromARGB(179, 16, 84, 171),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              cacheWidth: 132,
              cacheHeight: 132,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 66,
                  height: 66,
                  color: Colors.white10,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: text),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final String url;
  const _GalleryThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white10,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : Colors.white70;
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAudioPlayer extends StatelessWidget {
  final String title;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final bool isPlaying;

  const _BottomAudioPlayer({
    required this.title,
    required this.onPlayPause,
    required this.onStop,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 5, 11, 26),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Album art placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 12),
          // Title and controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {}, // Previous track
                      child: Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onPlayPause,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {}, // Next track
                      child: Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: onStop,
            child: Icon(
              Icons.close,
              color: Colors.white54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
