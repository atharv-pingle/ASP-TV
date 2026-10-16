import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/tv_theme.dart';

class TVQuickGuide extends StatelessWidget {
  final List<Channel> playlist;
  final Channel currentChannel;
  final ValueChanged<Channel> onChannelSelected;
  final VoidCallback onClose;

  const TVQuickGuide({
    Key? key,
    required this.playlist,
    required this.currentChannel,
    required this.onChannelSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      color: TVTheme.sidebarBackground.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.black26,
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, color: TVTheme.focusColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Quick Channel Guide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: TVTheme.textMuted, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Channel List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                final ch = playlist[index];
                final isCurrent = ch.id == currentChannel.id;

                return _QuickGuideItem(
                  channel: ch,
                  index: index + 1,
                  isCurrent: isCurrent,
                  onSelect: () => onChannelSelected(ch),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGuideItem extends StatefulWidget {
  final Channel channel;
  final int index;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _QuickGuideItem({
    Key? key,
    required this.channel,
    required this.index,
    required this.isCurrent,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<_QuickGuideItem> createState() => _QuickGuideItemState();
}

class _QuickGuideItemState extends State<_QuickGuideItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.isCurrent,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused
                ? TVTheme.focusColor
                : widget.isCurrent
                    ? TVTheme.cardFocusBackground
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : widget.isCurrent
                      ? TVTheme.focusColor
                      : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '${widget.index}'.padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isFocused ? Colors.black87 : TVTheme.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                height: 32,
                child: widget.channel.logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.channel.logo,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/tv-icon.png',
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset('assets/images/tv-icon.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _isFocused || widget.isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: _isFocused ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
              if (widget.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: TVTheme.accentRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PLAYING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
