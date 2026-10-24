import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/epg_service.dart';
import '../theme/tv_theme.dart';

/// Free-My-TV inspired dark launcher channel tile:
/// Sleek frosted glass surface, elevated logo stage, emerald LIVE indicator,
/// and luminous high-contrast white focus elevation with deep 3D drop shadow.
class TVChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;
  final bool autoFocus;
  final FocusNode? focusNode;
  final VoidCallback? onLeftToSidebar;
  final VoidCallback? onUpToSearch;

  const TVChannelCard({
    Key? key,
    required this.channel,
    required this.onSelect,
    required this.onToggleFavorite,
    this.autoFocus = false,
    this.focusNode,
    this.onLeftToSidebar,
    this.onUpToSearch,
  }) : super(key: key);

  @override
  State<TVChannelCard> createState() => _TVChannelCardState();
}

class _TVChannelCardState extends State<TVChannelCard> {
  late final FocusNode _effectiveFocusNode;
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;
  bool _isSelectKeyDown = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode(debugLabel: 'Card_${widget.channel.id}');
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _effectiveFocusNode.hasFocus) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key.keyId == 0x00100000017 || // KEYCODE_DPAD_CENTER
        key.keyId == 0x00100000042 || // KEYCODE_ENTER
        key.keyLabel.toLowerCase() == 'select' ||
        key.keyLabel.toLowerCase() == 'enter';
  }

  void _onKeyDown(LogicalKeyboardKey key) {
    if (!_isSelectKey(key)) return;
    if (_isSelectKeyDown) return;
    _isSelectKeyDown = true;
    _longPressTriggered = false;
    _longPressTimer?.cancel();
    // 600ms hold triggers favorite toggle via remote
    _longPressTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _longPressTriggered = true;
        widget.onToggleFavorite();
        _showFavoriteFeedback();
      }
    });
  }

  void _onKeyUp(LogicalKeyboardKey key) {
    if (!_isSelectKey(key)) return;
    _isSelectKeyDown = false;
    if (_longPressTimer != null && _longPressTimer!.isActive) {
      _longPressTimer!.cancel();
    }

    // Normal tap: open player if long-press was not triggered
    if (!_longPressTriggered) {
      widget.onSelect();
    }
    _longPressTriggered = false;
  }

  void _showFavoriteFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        backgroundColor: const Color(0xFF1B1C22),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: TVTheme.gold.withOpacity(0.5), width: 1.2),
        ),
        content: Row(
          children: [
            Icon(
              widget.channel.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: widget.channel.isFavorite ? TVTheme.gold : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.channel.isFavorite
                    ? '⭐ Added "${widget.channel.name}" to Favorites'
                    : 'Removed "${widget.channel.name}" from Favorites',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (widget.channel.logo.isNotEmpty) {
      if (widget.channel.logo.startsWith('assets/')) {
        return Image.asset(
          widget.channel.logo,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildLogoFallback(),
        );
      }
      return CachedNetworkImage(
        imageUrl: widget.channel.logo,
        fit: BoxFit.contain,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 12; Android TV; Build/STT2.220920.015) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        },
        memCacheWidth: 400,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TVTheme.focusColor.withOpacity(0.4),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildLogoFallback(),
      );
    }
    return _buildLogoFallback();
  }

  Widget _buildLogoFallback() {
    final initials = widget.channel.name.trim().isNotEmpty
        ? widget.channel.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(3).join()
        : 'TV';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.live_tv_rounded, size: 34, color: TVTheme.focusColor),
          const SizedBox(height: 6),
          Text(
            initials.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autoFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft && widget.onLeftToSidebar != null) {
            widget.onLeftToSidebar!();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowUp && widget.onUpToSearch != null) {
            widget.onUpToSearch!();
            return KeyEventResult.handled;
          }
          if (_isSelectKey(key)) {
            _onKeyDown(key);
            return KeyEventResult.handled;
          }
        } else if (event is KeyUpEvent) {
          final key = event.logicalKey;
          if (_isSelectKey(key)) {
            _onKeyUp(key);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: () {
          widget.onToggleFavorite();
          _showFavoriteFeedback();
        },
        child: AnimatedScale(
          scale: _isFocused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: EdgeInsets.all(_isFocused ? 0 : 3),
            decoration: BoxDecoration(
              // Free-My-TV dark launcher card styling
              gradient: LinearGradient(
                colors: _isFocused
                    ? [const Color(0xFF2E303A), const Color(0xFF22242D)]
                    : [const Color(0xFF1E2027), const Color(0xFF14151B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isFocused ? Colors.white : Colors.white.withOpacity(0.08),
                width: _isFocused ? 2.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.65),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: TVTheme.focusColor.withOpacity(0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    children: [
                      // Elevated Clean Logo Stage - Maximized for visibility on TV
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: _buildLogo(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Channel Name Text
                      Text(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
                          color: _isFocused ? Colors.white : TVTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // EPG Program or Live Tag
                      Builder(
                        builder: (context) {
                          final liveProgram =
                              EpgService.instance.getCurrentProgram(widget.channel);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: TVTheme.liveGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: TVTheme.liveGreen.withOpacity(0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  liveProgram != null ? liveProgram.title : 'LIVE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _isFocused
                                        ? Colors.white.withOpacity(0.85)
                                        : TVTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Favorite Star Indicator (Top Right)
                if (widget.channel.isFavorite)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: TVTheme.gold.withOpacity(0.5), width: 1),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: TVTheme.gold,
                        size: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
