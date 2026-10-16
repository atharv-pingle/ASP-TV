import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autoFocus,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onToggleFavorite,
        child: AnimatedScale(
          scale: _isFocused ? 1.06 : 1.0,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top row: LIVE badge + Favorite Star
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TVTheme.accentRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.channel.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        color: widget.channel.isFavorite
                            ? TVTheme.gold
                            : TVTheme.textMuted,
                      ),
                      onPressed: widget.onToggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Channel Logo
                Expanded(
                  child: Center(
                    child: widget.channel.logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.channel.logo,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TVTheme.focusColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/tv-icon.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/images/tv-icon.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Channel Name
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
                const SizedBox(height: 4),

                // Language Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.channel.languageName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TVTheme.textSecondary,
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
