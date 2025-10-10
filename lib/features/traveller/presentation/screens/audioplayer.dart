import 'package:flutter/material.dart';

class BottomAudioPlayer extends StatefulWidget {
  final String title;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<double> onSeek;
  final ValueChanged<double>? onSpeedChange;
  final VoidCallback? onReplay;
  final VoidCallback? onForward;
  final bool isPlaying;
  final ValueNotifier<double> currentPositionNotifier;
  final double totalDuration;
  final String progressText; // e.g., "2/5"
  final String? durationText; // e.g., "5:00"

  const BottomAudioPlayer({
    required this.title,
    required this.onPlayPause,
    required this.onStop,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    this.onSpeedChange,
    this.onReplay,
    this.onForward,
    required this.isPlaying,
    required this.currentPositionNotifier,
    required this.totalDuration,
    required this.progressText,
    this.durationText,
    Key? key,
  }) : super(key: key);

  @override
  _BottomAudioPlayerState createState() => _BottomAudioPlayerState();
}

class _BottomAudioPlayerState extends State<BottomAudioPlayer> {
  double currentSpeed = 1.0;

  void _showSpeedOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Playback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...[0.5, 1.0, 1.5].map((speed) => ListTile(
                title: Text(
                  '${speed}x',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: currentSpeed == speed
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    currentSpeed = speed;
                  });
                  widget.onSpeedChange?.call(speed);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _skipBackward() {
    // Default skip backward by 10 seconds if no callback provided
    final currentPosition = widget.currentPositionNotifier.value;
    final newPosition = (currentPosition - 10).clamp(0.0, widget.totalDuration);
    widget.onSeek(newPosition);
  }

  void _skipForward() {
    // Default skip forward by 10 seconds if no callback provided
    final currentPosition = widget.currentPositionNotifier.value;
    final newPosition = (currentPosition + 10).clamp(0.0, widget.totalDuration);
    widget.onSeek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 11, 26),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + progress badge
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  widget.progressText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          // Duration text below title
          if (widget.durationText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.durationText!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Speed control + slider with time labels + replay button
          ValueListenableBuilder<double>(
            valueListenable: widget.currentPositionNotifier,
            builder: (context, currentPosition, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Speed control button
                  GestureDetector(
                    onTap: _showSpeedOptions,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${currentSpeed}x\nspeed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Replay button (skip backward)
                  GestureDetector(
                    onTap: widget.onReplay ?? _skipBackward,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.replay,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  Expanded(
                    child: SizedBox(
                      height: 40, // Match button height for perfect alignment
                      child: Stack(
                        children: [
                          // Slider centered vertically
                          Align(
                            alignment: Alignment.center,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                thumbColor: Colors.white,
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                              ),
                              child: Slider(
                                value: currentPosition,
                                min: 0,
                                max: widget.totalDuration,
                                onChanged: widget.onSeek,
                              ),
                            ),
                          ),
                          // Time labels positioned at bottom
                          Positioned(
                            bottom: -4,
                            left: 12,
                            right: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(currentPosition),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                Text(
                                  '-${_formatTime(widget.totalDuration - currentPosition)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Forward button (skip forward)
                  GestureDetector(
                    onTap: widget.onForward ?? _skipForward,
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                onPressed: widget.onPrevious,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: widget.onPlayPause,
                child: Container(
                  width: 156,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                onPressed: widget.onNext,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to format time
  String _formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
}