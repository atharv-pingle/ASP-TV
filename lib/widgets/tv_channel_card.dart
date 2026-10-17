import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/tv_theme.dart';

class TVChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;
  final bool autoFocus;

  const TVChannelCard({
    Key? key,
    required this.channel,
    required this.onSelect,
    required this.onToggleFavorite,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<TVChannelCard> createState() => _TVChannelCardState();
}

class _TVChannelCardState extends State<TVChannelCard> {
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
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
    if (_longPressTimer != null && _longPressTimer!.isActive) return;

    _longPressTriggered = false;
    // 600ms hold triggers favorite toggle via remote
    _longPressTimer = Timer(const Duration(milliseconds: 600), () {
      _longPressTriggered = true;
      widget.onToggleFavorite();
      _showFavoriteFeedback();
    });
  }

  void _onKeyUp(LogicalKeyboardKey key) {
    if (!_isSelectKey(key)) return;

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
        backgroundColor: widget.channel.isFavorite ? TVTheme.cardFocusBackground : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TVTheme.focusColor.withOpacity(0.5),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.live_tv_rounded, size: 36, color: TVTheme.focusColor),
          const SizedBox(height: 6),
          Text(
            initials.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
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
      autofocus: widget.autoFocus,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (_isSelectKey(event.logicalKey)) {
            _onKeyDown(event.logicalKey);
            return KeyEventResult.handled;
          }
        } else if (event is KeyUpEvent) {
          if (_isSelectKey(event.logicalKey)) {
            _onKeyUp(event.logicalKey);
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
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _isFocused
                  ? TVTheme.cardFocusBackground
                  : TVTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? TVTheme.focusColor : Colors.white10,
                width: _isFocused ? 3.0 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: TVTheme.focusGlow,
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
            ),
            child: Stack(
              children: [
                // Main Content: Prominent Logo + Channel Name Text Underneath
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      // Prominent Channel Logo
                      Expanded(
                        child: Center(
                          child: _buildLogo(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Channel Name Text Underneath
                      Text(
                        widget.channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              _isFocused ? FontWeight.bold : FontWeight.w600,
                          color: _isFocused
                              ? TVTheme.focusColor
                              : TVTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle Favorite Star Indicator (Top Right)
                if (widget.channel.isFavorite)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: TVTheme.gold.withOpacity(0.5), width: 1),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: TVTheme.gold,
                        size: 16,
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
