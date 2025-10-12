import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/tour_package.dart';
import './audio_player_widget.dart';
import './tour_route_map.dart';
import './tour_stop_map.dart';
import '../services/media_service.dart';

class TourStopCard extends StatefulWidget {
  final TourStop stop;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;

  const TourStopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    this.onMapTap,
  });

  @override
  State<TourStopCard> createState() => _TourStopCardState();
}

class _TourStopCardState extends State<TourStopCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header section - always visible
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop number
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Stop details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stop.stopName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.stop.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.stop.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (widget.stop.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white54, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.stop.location!.formattedAddress,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Expand/collapse button
                IconButton(
                  onPressed: widget.onTap,
                  icon: Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // Expanded content
          if (widget.isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Map for this stop
                  if (widget.stop.location != null) ...[
                    _buildStopMap(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Media section
                  if (widget.stop.mediaUrls.isNotEmpty) ...[
                    _buildMediaSection(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TourStopMap(
              stopLocation: widget.stop.location!,
              stopName: widget.stop.stopName,
              stopNumber: widget.index + 1,
              onMapTap: widget.onMapTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
  final images = widget.stop.media
      .where((media) => media.mediaType == MediaType.image)
      .toList();
  final audios = widget.stop.media
      .where((media) => media.mediaType == MediaType.audio)
      .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (images.isNotEmpty) ...[
        const Text(
          'Images',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final media = images[index];
              final fullImageUrl = MediaService.getFullUrl(media.url);
              
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < images.length - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Image load error: $error for URL: $fullImageUrl');
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, color: Colors.white54),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      
      if (audios.isNotEmpty) ...[
        const Text(
          'Audio Guides',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: audios.asMap().entries.map((entry) {
            final index = entry.key;
            final audio = entry.value;
            final fullAudioUrl = MediaService.getFullUrl(audio.url);
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < audios.length - 1 ? 12 : 0),
              child: AudioPlayerWidget(
                audioUrl: fullAudioUrl,
                title: 'Audio ${index + 1}',
              ),
            );
          }).toList(),
        ),
      ],
    ],
  );
}
}