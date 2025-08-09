import 'package:flutter/material.dart';

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2CC3B5);
    return MaterialApp(
      title: 'Travel Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1220),
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

  static const heroImage =
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop';

  static const tanahLotPhotos = <String>[
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1483683804023-6ccdb62f86ef?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1482192505345-5655af888cc4?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1600&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1494475673543-6a6a27143b22?q=80&w=1600&auto=format&fit=crop',
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
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade700),
                  ),
                  const _TopToBottomShade(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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
                          _CircleIconButton(
                            icon: Icons.ios_share,
                            onTap: () {},
                          ),
                        ],
                      ),
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
              bottom: bottomInset + 160, // space for CTA + nav
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _DetailsSection(),
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
                              title: 'Gallery', photos: tanahLotPhotos),
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
                      itemBuilder: (context, index) =>
                          _GalleryThumb(url: tanahLotPhotos[index]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Trip list section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Trip to Indonesia',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(7, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TripCard(
                            item: TripItem(
                              title: 'Raja Ampat Islands',
                              location: 'Papua',
                              duration: '1 hr 30 min',
                              image: tanahLotPhotos[0],
                              isNew: index < 2,
                            ),
                            
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom controls
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting your trip...')),
                    );
                  },
                  child: const Text('Start a Trip'),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(40),
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
}

/* ------------------------------ Gallery Page ------------------------------- */

class GalleryPage extends StatelessWidget {
  final String title;
  final List<String> photos;

  const GalleryPage({super.key, required this.title, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final url = photos[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.white10,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade700),
              ),
            ),
          );
        },
      ),
    );
  }
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

// Details card shown below the image
class _DetailsSection extends StatelessWidget {
  const _DetailsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1730).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: const [
          // Title + rating
          _TitleRow(),
          SizedBox(height: 8),
          _PlaceDescription(),
          SizedBox(height: 12),
          _InfoGrid(),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: Text(
            'Tanah Lot Temple (Pura Tanah Lot)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        SizedBox(width: 8),
        _RatingPill(rating: 4.8, reviews: '5,639'),
      ],
    );
  }
}

class _PlaceDescription extends StatelessWidget {
  const _PlaceDescription();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Tanah Lot Temple is one of Bali’s most iconic landmarks, known for its stunning offshore setting '
      'and beautiful sunset views. The temple is perched on a rock formation, surrounded by the sea during '
      'high tide, which makes it a magical place to visit.',
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: _InfoPill(
                icon: Icons.place_outlined,
                title: 'Bali, Indonesia',
                caption: 'Temple, Surf, Sunset',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                icon: Icons.cloud_queue,
                title: '28-31°C',
                caption: 'Season: Dry',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InfoPill(
                icon: Icons.paid_outlined,
                title: '\$5 - \$15 USD',
                caption: 'Entry tickets available',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                icon: Icons.access_time,
                title: '6:00 - 19:00',
                caption: 'Best: Sunset',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final String reviews;

  const _RatingPill({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            '4.8',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text('  (5,639)',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;

  const _InfoPill({
    required this.icon,
    required this.title,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF101A36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
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
    final text = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: text),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            )
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
        child: Ink.image(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          child: InkWell(onTap: () {}),
        ),
      ),
    );
  }
}

/* ------------------------------ Trip List ------------------------------- */

class TripItem {
  final String title;
  final String location;
  final String duration;
  final String image;
  final bool isNew;

  TripItem({
    required this.title,
    required this.location,
    required this.duration,
    required this.image,
    this.isNew = false,
  });
}

class _TripCard extends StatelessWidget {
  final TripItem item;
  const _TripCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.image,
              width: 66,
              height: 66,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 66,
                height: 66,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (item.isNew)
                      _Badge(label: 'Preview', color: cs.primary),
                  ],
                ),
                const SizedBox(height: 8),
                // Meta rows
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      item.duration,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withOpacity(0.15),
        shape: StadiumBorder(
            side: BorderSide(color: color.withOpacity(0.3))),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
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
                  fontSize: 11, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}