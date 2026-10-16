import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/channel_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_quick_guide.dart';

class TVPlayerScreen extends StatefulWidget {
  final Channel initialChannel;
  final List<Channel> playlist;
  final ChannelService channelService;

  const TVPlayerScreen({
    Key? key,
    required this.initialChannel,
    required this.playlist,
    required this.channelService,
  }) : super(key: key);

  @override
  State<TVPlayerScreen> createState() => _TVPlayerScreenState();
}

class _TVPlayerScreenState extends State<TVPlayerScreen> {
  late Channel _currentChannel;
  int _currentStreamIndex = 0;
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool _showOsd = true;
  Timer? _osdTimer;
  bool _showQuickGuide = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel;
    WakelockPlus.enable();
    _playChannel(_currentChannel);
  }

  void _playChannel(Channel channel) {
    _currentChannel = channel;
    _currentStreamIndex = 0;
    _startStream();
  }

  void _startStream() {
    _controller?.removeListener(_checkStreamHealth);
    _controller?.dispose();
    _controller = null;

    if (_currentChannel.streams.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No stream URL available for this channel';
      });
      _scheduleOsdHide();
      return;
    }

    final streamUrl = _currentChannel.streams[_currentStreamIndex].trim();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _showOsd = true;
    });

    _scheduleOsdHide();

    // Configure VideoPlayerController with HLS format hint & TV User-Agent
    final isHls = streamUrl.toLowerCase().contains('.m3u8');
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(streamUrl),
      formatHint: isHls ? VideoFormat.hls : null,
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 12; Android TV; Build/STT2.220920.015) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Origin': 'https://www.google.com',
        'Referer': 'https://www.google.com/',
      },
    );

    _controller = controller;

    controller.initialize().then((_) {
      if (!mounted || _controller != controller) return;
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      controller.play();
      controller.addListener(_checkStreamHealth);
    }).catchError((error) {
      if (!mounted || _controller != controller) return;
      _handleStreamFailure('Connection error: $error');
    });
  }

  void _checkStreamHealth() {
    final c = _controller;
    if (c != null && c.value.hasError && mounted && !_hasError) {
      _handleStreamFailure(c.value.errorDescription ?? 'Playback error');
    }
  }

  void _handleStreamFailure(String errorDetail) {
    // Attempt next stream mirror automatically
    if (_currentStreamIndex + 1 < _currentChannel.streams.length) {
      setState(() {
        _currentStreamIndex++;
      });
      _startStream();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Stream unavailable. Press retry or change channel.';
        _showOsd = true;
      });
    }
  }

  void _cycleStreamMirror() {
    if (_currentChannel.streams.length > 1) {
      setState(() {
        _currentStreamIndex = (_currentStreamIndex + 1) % _currentChannel.streams.length;
      });
      _startStream();
    }
  }

  void _scheduleOsdHide() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_hasError && !_showQuickGuide) {
        setState(() {
          _showOsd = false;
        });
      }
    });
  }

  void _nextChannel() {
    final idx = widget.playlist.indexWhere((c) => c.id == _currentChannel.id);
    if (idx != -1 && widget.playlist.isNotEmpty) {
      final nextIdx = (idx + 1) % widget.playlist.length;
      _playChannel(widget.playlist[nextIdx]);
    }
  }

  void _prevChannel() {
    final idx = widget.playlist.indexWhere((c) => c.id == _currentChannel.id);
    if (idx != -1 && widget.playlist.isNotEmpty) {
      final prevIdx = (idx - 1 + widget.playlist.length) % widget.playlist.length;
      _playChannel(widget.playlist[prevIdx]);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Up Arrow: Prev Channel (TV Zapping)
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (!_showQuickGuide) {
        _prevChannel();
        return KeyEventResult.handled;
      }
    }

    // Down Arrow: Next Channel (TV Zapping)
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!_showQuickGuide) {
        _nextChannel();
        return KeyEventResult.handled;
      }
    }

    // Left/Right Arrow: Switch stream mirror if available
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && !_showQuickGuide) {
      if (_currentChannel.streams.length > 1) {
        _cycleStreamMirror();
        return KeyEventResult.handled;
      }
    }

    // Select / OK / Enter: Toggle Quick Guide
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      setState(() {
        _showQuickGuide = !_showQuickGuide;
        _showOsd = true;
      });
      if (!_showQuickGuide) _scheduleOsdHide();
      return KeyEventResult.handled;
    }

    // Back / Escape: Exit quick guide or return to Home
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      if (_showQuickGuide) {
        setState(() {
          _showQuickGuide = false;
        });
        _scheduleOsdHide();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _osdTimer?.cancel();
    _controller?.removeListener(_checkStreamHealth);
    _controller?.dispose();
    _focusNode.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelIndex = widget.playlist.indexWhere((c) => c.id == _currentChannel.id) + 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showOsd = !_showOsd;
            });
            if (_showOsd) _scheduleOsdHide();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fullscreen Video Player (16:9 Aspect Ratio)
              Center(
                child: _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller!),
                      )
                    : const SizedBox.shrink(),
              ),

              // 2. Loading Spinner
              if (_isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          color: TVTheme.focusColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to live broadcast...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Stream Error State
              if (_hasError)
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.signal_wifi_connected_no_internet_4,
                            size: 64, color: TVTheme.accentRed),
                        const SizedBox(height: 16),
                        Text(
                          _currentChannel.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: TVTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TVTheme.focusColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Stream'),
                              onPressed: _startStream,
                            ),
                            if (_currentChannel.streams.length > 1) ...[
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.swap_horiz),
                                label: Text('Try Mirror (${_currentStreamIndex + 1}/${_currentChannel.streams.length})'),
                                onPressed: _cycleStreamMirror,
                              ),
                            ],
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Next Channel'),
                              onPressed: _nextChannel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. On-Screen Display (OSD Banner at Bottom)
              if (_showOsd)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xE60F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Channel Number
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: TVTheme.focusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: TVTheme.focusColor),
                          ),
                          child: Text(
                            'CH ${channelIndex.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TVTheme.focusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Channel Logo
                        if (_currentChannel.logo.isNotEmpty)
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CachedNetworkImage(
                              imageUrl: _currentChannel.logo,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/tv-icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),

                        // Channel Title & Language
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentChannel.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TVTheme.accentRed,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentChannel.languageName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: TVTheme.textSecondary,
                                    ),
                                  ),
                                  if (_currentChannel.streams.length > 1) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _cycleStreamMirror,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: TVTheme.focusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                              color: TVTheme.focusColor.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          '⚡ Stream ${_currentStreamIndex + 1}/${_currentChannel.streams.length} (Tap / ► to Switch)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: TVTheme.focusColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),

                        // TV Remote Hints
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildKeyHint('▲ / ▼', 'Change Channel'),
                            const SizedBox(width: 14),
                            _buildKeyHint('OK', 'Guide'),
                            const SizedBox(width: 14),
                            _buildKeyHint('BACK', 'Exit'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 5. Quick Channel Guide Drawer Overlay (Side Sheet)
              if (_showQuickGuide)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: TVQuickGuide(
                    playlist: widget.playlist,
                    currentChannel: _currentChannel,
                    onChannelSelected: (ch) {
                      setState(() {
                        _showQuickGuide = false;
                      });
                      _playChannel(ch);
                    },
                    onClose: () {
                      setState(() {
                        _showQuickGuide = false;
                      });
                      _scheduleOsdHide();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyHint(String keyLabel, String action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: TVTheme.focusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            action,
            style: const TextStyle(
              fontSize: 11,
              color: TVTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
