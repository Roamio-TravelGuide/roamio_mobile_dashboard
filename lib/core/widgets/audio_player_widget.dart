import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../services/media_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String title;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  Duration? _duration;
  Duration? _position;
  double _loadingProgress = 0.0;
  Timer? _loadingTimer;
  final GlobalKey _progressBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.playing) {
            _isLoading = false;
            _stopLoadingAnimation();
          } else if (state == PlayerState.stopped) {
            _position = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  void _startLoadingAnimation() {
    _loadingProgress = 0.0;
    _loadingTimer?.cancel(); // Cancel any existing timer
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _loadingProgress += 0.02;
          if (_loadingProgress >= 1.0) {
            _loadingProgress = 0.0;
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (mounted) {
      setState(() {
        _loadingProgress = 0.0;
      });
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _stopLoadingAnimation();
      } else {
        // Check if URL is empty - if so, show error immediately
        if (widget.audioUrl.isEmpty) {
          print('AudioPlayerWidget: No audio URL provided');
          setState(() {
            _hasError = true;
            _isPlaying = false;
            _isLoading = false;
          });
          return;
        }

        // Don't double-process URLs that are already full URLs
        final fullUrl = widget.audioUrl.startsWith('http')
            ? widget.audioUrl
            : MediaService.getFullUrl(widget.audioUrl);

        print('AudioPlayerWidget: Attempting to play URL: $fullUrl');

        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
        }

        _startLoadingAnimation();

        // For web, try a different approach - use setSourceUrl first, then UrlSource as fallback
        try {
          await _audioPlayer.setSourceUrl(fullUrl);
          print('AudioPlayerWidget: setSourceUrl succeeded');
        } catch (e) {
          print(
            'AudioPlayerWidget: setSourceUrl failed ($e), trying UrlSource',
          );
          try {
            await _audioPlayer.setSource(UrlSource(fullUrl));
            print('AudioPlayerWidget: UrlSource succeeded');
          } catch (e2) {
            print('AudioPlayerWidget: UrlSource also failed ($e2)');
            // Try one more approach - AssetSource for web-compatible URLs
            try {
              print('AudioPlayerWidget: Trying AssetSource as last resort');
              await _audioPlayer.setSource(AssetSource(fullUrl));
              print('AudioPlayerWidget: AssetSource succeeded');
            } catch (e3) {
              print('AudioPlayerWidget: All source methods failed');
              throw e3; // Re-throw the last error
            }
          }
        }

        // Then play
        await _audioPlayer.resume();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _stopLoadingAnimation();
      }
    } catch (error) {
      print('AudioPlayerWidget: Playback error: $error');
      print('AudioPlayerWidget: Failed URL: ${widget.audioUrl}');
      _stopLoadingAnimation();
      if (mounted) {
        setState(() {
          _hasError = true;
          _isPlaying = false;
          _isLoading = false;
        });
      }
    }
  }

  void _cancelLoading() {
    if (_isLoading) {
      _audioPlayer.stop();
      _stopLoadingAnimation();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    }
  }

  void _seekToPosition(Duration position) async {
    if (_duration != null && position <= _duration!) {
      try {
        await _audioPlayer.seek(position);
        if (!_isPlaying) {
          await _audioPlayer.resume();
        }
      } catch (error) {
        print('Seek error: $error');
      }
    }
  }

  void _onProgressBarTap(TapDownDetails details) {
    if (_duration == null || _duration!.inSeconds == 0) return;

    final RenderBox renderBox =
        _progressBarKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.globalPosition);
    final progressBarWidth = renderBox.size.width;
    final tapPosition = offset.dx;

    if (tapPosition >= 0 && tapPosition <= progressBarWidth) {
      final percentage = tapPosition / progressBarWidth;
      final newPosition = Duration(
        seconds: (_duration!.inSeconds * percentage).round(),
      );

      _seekToPosition(newPosition);
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progressValue {
    if (_isLoading) {
      return _loadingProgress;
    } else if (_duration != null &&
        _duration!.inSeconds > 0 &&
        _position != null) {
      return _position!.inSeconds / _duration!.inSeconds;
    }
    return 0.0;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _loadingTimer?.cancel();
    _loadingTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Main content row
          Row(
            children: [
              // Play/Pause/Loading button
              GestureDetector(
                onTap: _isLoading ? _cancelLoading : _togglePlayback,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: _isLoading
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Loading progress circle
                      if (_isLoading)
                        CircularProgressIndicator(
                          value: _loadingProgress,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.2),
                        ),

                      // Play/Pause/Error icon
                      if (!_isLoading)
                        Icon(
                          _hasError
                              ? Icons.error
                              : _isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: _hasError ? Colors.red : Colors.white,
                          size: 20,
                        )
                      else
                        // Cancel icon during loading
                        Icon(Icons.close, color: Colors.red, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Time and status
                    Row(
                      children: [
                        // Current time
                        Text(
                          _isLoading
                              ? 'Loading...'
                              : _formatDuration(_position),
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.blue[300]
                                : Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),

                        const Spacer(),

                        // Total duration / Loading percentage
                        Text(
                          _isLoading
                              ? '${(_loadingProgress * 100).toStringAsFixed(0)}%'
                              : _formatDuration(_duration),
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.blue[300]
                                : Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Retry button for errors
              if (_hasError)
                IconButton(
                  onPressed: _togglePlayback,
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  tooltip: 'Retry',
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar with seek functionality
          GestureDetector(
            onTapDown: _onProgressBarTap,
            child: Container(
              key: _progressBarKey,
              height: 16, // Increased height for better touch area
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          width: double.infinity,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.transparent,
                          ),
                        ),

                        // Progress - This now works for both loading and playing
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width:
                              MediaQuery.of(context).size.width *
                              _progressValue,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _hasError
                                ? Colors.red
                                : _isLoading
                                ? Colors.blue
                                : const Color(0xFF6366F1),
                          ),
                        ),

                        // Loading animation (pulse effect) - only show during loading
                        if (_isLoading)
                          Positioned(
                            left:
                                MediaQuery.of(context).size.width *
                                    _loadingProgress -
                                8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Playhead indicator when not loading
                        if (!_isLoading &&
                            _duration != null &&
                            _duration!.inSeconds > 0)
                          Positioned(
                            left:
                                MediaQuery.of(context).size.width *
                                    _progressValue -
                                6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6366F1),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 2,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status message
          if (_hasError || _isLoading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasError ? Icons.error_outline : Icons.downloading,
                  size: 12,
                  color: _hasError ? Colors.red[300] : Colors.blue[300],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _hasError
                        ? 'Failed to load audio. Tap retry to try again.'
                        : 'Downloading audio... Tap to cancel',
                    style: TextStyle(
                      color: _hasError ? Colors.red[300] : Colors.blue[300],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
