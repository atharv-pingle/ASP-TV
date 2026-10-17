import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/channel_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_quick_guide.dart';

enum VideoScaleMode { stretch, fit, zoom }

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

  VideoScaleMode _scaleMode = VideoScaleMode.stretch;
  String _hudMessage = '';
  Timer? _hudTimer;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel;
    _loadScaleModePreference();
    _playChannel(_currentChannel);
  }

  void _loadScaleModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIdx = prefs.getInt('asp_tv_scale_mode') ?? 0; // Default: stretch
      if (mounted) {
        setState(() {
          _scaleMode = VideoScaleMode.values[modeIdx.clamp(0, VideoScaleMode.values.length - 1)];
        });
      }
    } catch (_) {}
  }

  void _saveScaleModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('asp_tv_scale_mode', _scaleMode.index);
    } catch (_) {}
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

  void _cycleScaleMode() {
    setState(() {
      switch (_scaleMode) {
        case VideoScaleMode.stretch:
          _scaleMode = VideoScaleMode.fit;
          break;
        case VideoScaleMode.fit:
          _scaleMode = VideoScaleMode.zoom;
          break;
        case VideoScaleMode.zoom:
          _scaleMode = VideoScaleMode.stretch;
          break;
      }
      _showOsd = true;
    });
    _triggerHud('Display: ${_getScaleModeLabel()}');
    _scheduleOsdHide();
    _saveScaleModePreference();
  }

  void _triggerHud(String message) {
    _hudTimer?.cancel();
    setState(() {
      _hudMessage = message;
    });
    _hudTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hudMessage = '';
        });
      }
    });
  }

  String _getScaleModeLabel() {
    switch (_scaleMode) {
      case VideoScaleMode.stretch:
        return 'Stretch (Full Screen)';
      case VideoScaleMode.fit:
        return 'Fit (Original 16:9)';
      case VideoScaleMode.zoom:
        return 'Zoom (Crop)';
    }
  }

  IconData _getScaleModeIcon() {
    switch (_scaleMode) {
      case VideoScaleMode.stretch:
        return Icons.aspect_ratio_rounded;
      case VideoScaleMode.fit:
        return Icons.fit_screen_rounded;
      case VideoScaleMode.zoom:
        return Icons.zoom_out_map_rounded;
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

    final key = event.logicalKey;

    // Detect Channel Up (CH+ / PageUp / ArrowUp / keycode 166)
    final isChannelUp = key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.arrowUp ||
        key.keyId == 0x001000000a6 || // KEYCODE_CHANNEL_UP
        key.keyLabel.toLowerCase().contains('channel up');

    // Detect Channel Down (CH- / PageDown / ArrowDown / keycode 167)
    final isChannelDown = key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.arrowDown ||
        key.keyId == 0x001000000a7 || // KEYCODE_CHANNEL_DOWN
        key.keyLabel.toLowerCase().contains('channel down');

    // Channel Switching
    if (isChannelUp) {
      if (!_showQuickGuide) {
        _prevChannel();
        return KeyEventResult.handled;
      }
    }

    if (isChannelDown) {
      if (!_showQuickGuide) {
        _nextChannel();
        return KeyEventResult.handled;
      }
    }

    // Left Arrow: Cycle Video Stretch / Fit mode
    if (key == LogicalKeyboardKey.arrowLeft && !_showQuickGuide) {
      _cycleScaleMode();
      return KeyEventResult.handled;
    }

    // Right Arrow: Switch stream mirror if available
    if (key == LogicalKeyboardKey.arrowRight && !_showQuickGuide) {
      if (_currentChannel.streams.length > 1) {
        _cycleStreamMirror();
        return KeyEventResult.handled;
      }
    }

    // Select / OK / Enter: Toggle Quick Guide
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key.keyId == 0x00100000017 || // KEYCODE_DPAD_CENTER
        key.keyId == 0x00100000042 || // KEYCODE_ENTER
        key.keyLabel.toLowerCase() == 'select' ||
        key.keyLabel.toLowerCase() == 'enter') {
      setState(() {
        _showQuickGuide = !_showQuickGuide;
        _showOsd = true;
      });
      if (!_showQuickGuide) _scheduleOsdHide();
      return KeyEventResult.handled;
    }

    // Back / Escape: Exit quick guide or return to Home
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack) {
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
    _hudTimer?.cancel();
    _controller?.removeListener(_checkStreamHealth);
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildVideo() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final videoWidth = c.value.size.width > 0 ? c.value.size.width : 16.0;
    final videoHeight = c.value.size.height > 0 ? c.value.size.height : 9.0;
    final aspectRatio = c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;

    switch (_scaleMode) {
      case VideoScaleMode.stretch:
        // Stretch video to fit full 16:9 screen edge-to-edge
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(c),
            ),
          ),
        );
      case VideoScaleMode.zoom:
        // Fill screen preserving aspect ratio (crop edges)
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(c),
            ),
          ),
        );
      case VideoScaleMode.fit:
      default:
        // Preserve native broadcast aspect ratio
        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(c),
          ),
        );
    }
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
              // 1. Fullscreen Video with Stretch & Fit support
              _buildVideo(),

              // Top-Left Touch Back Button (Easy touch interface navigation)
              if (_showOsd || _hasError)
                Positioned(
                  top: 28,
                  left: 28,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Guide',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. HUD Banner for Aspect Ratio / Mode changes
              if (_hudMessage.isNotEmpty)
                Positioned(
                  top: 36,
                  right: 36,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TVTheme.focusColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: TVTheme.focusColor.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getScaleModeIcon(), color: TVTheme.focusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _hudMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Loading Spinner
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

              // 4. Stream Error State
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
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
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

              // 5. Leanback TV Player OSD (Bottom Navigation Overlay)
              if (_showOsd)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
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
                            child: _currentChannel.logo.startsWith('assets/')
                                ? Image.asset(
                                    _currentChannel.logo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.live_tv_rounded, size: 28, color: TVTheme.focusColor),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _currentChannel.logo,
                                    fit: BoxFit.contain,
                                    httpHeaders: const {
                                      'User-Agent':
                                          'Mozilla/5.0 (Linux; Android 12; Android TV; Build/STT2.220920.015) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                    },
                                    errorWidget: (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.live_tv_rounded, size: 28, color: TVTheme.focusColor),
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
                                  const SizedBox(width: 12),

                                  // Video Stretch / Scale Mode Button
                                  GestureDetector(
                                    onTap: _cycleScaleMode,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _scaleMode == VideoScaleMode.stretch
                                            ? TVTheme.focusColor
                                            : Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _scaleMode == VideoScaleMode.stretch
                                              ? Colors.white
                                              : TVTheme.focusColor.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getScaleModeIcon(),
                                            size: 14,
                                            color: _scaleMode == VideoScaleMode.stretch
                                                ? Colors.black87
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _getScaleModeLabel(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _scaleMode == VideoScaleMode.stretch
                                                  ? Colors.black87
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  if (_currentChannel.streams.length > 1) ...[
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: _cycleStreamMirror,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: TVTheme.focusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                              color: TVTheme.focusColor.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          '⚡ Stream ${_currentStreamIndex + 1}/${_currentChannel.streams.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: TVTheme.focusColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // TV Remote Hints
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildKeyHint('◄', 'Stretch'),
                            const SizedBox(width: 12),
                            _buildKeyHint('CH ▲/▼', 'Channel'),
                            const SizedBox(width: 12),
                            _buildKeyHint('OK', 'Guide'),
                            const SizedBox(width: 12),
                            _buildKeyHint('BACK', 'Home'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 6. Quick Channel Guide Drawer Overlay (Side Sheet)
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
