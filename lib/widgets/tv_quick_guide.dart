import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/epg_service.dart';
import '../theme/tv_theme.dart';

class TVQuickGuide extends StatefulWidget {
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
  State<TVQuickGuide> createState() => _TVQuickGuideState();
}

class _TVQuickGuideState extends State<TVQuickGuide> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  int _selectedIndex = 0;
  static const double _itemHeight = 64.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode(debugLabel: 'TVQuickGuideFocus');

    _selectedIndex = widget.playlist.indexWhere((c) => c.id == widget.currentChannel.id);
    if (_selectedIndex == -1) _selectedIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _scrollToIndex(_selectedIndex, animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant TVQuickGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentChannel.id != widget.currentChannel.id) {
      final idx = widget.playlist.indexWhere((c) => c.id == widget.currentChannel.id);
      if (idx != -1 && idx != _selectedIndex) {
        setState(() {
          _selectedIndex = idx;
        });
        _scrollToIndex(_selectedIndex);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final targetOffset = ((index * _itemHeight) - 180.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key.keyId == 0x00100000017 ||
        key.keyId == 0x00100000042 ||
        key.keyLabel.toLowerCase() == 'select' ||
        key.keyLabel.toLowerCase() == 'enter';
  }

  bool _isBackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key.keyId == 0x00100000004 ||
        key.keyLabel.toLowerCase() == 'back';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (_selectedIndex > 0) {
        setState(() {
          _selectedIndex--;
        });
        _scrollToIndex(_selectedIndex);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_selectedIndex < widget.playlist.length - 1) {
        setState(() {
          _selectedIndex++;
        });
        _scrollToIndex(_selectedIndex);
      }
      return KeyEventResult.handled;
    }

    if (_isSelectKey(key)) {
      if (_selectedIndex >= 0 && _selectedIndex < widget.playlist.length) {
        widget.onChannelSelected(widget.playlist[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }

    if (_isBackKey(key) || key == LogicalKeyboardKey.arrowLeft) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: 390,
        decoration: BoxDecoration(
          color: const Color(0xF5111216),
          border: Border(left: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.75),
              blurRadius: 26,
              offset: const Offset(-8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guide Header (Free-My-TV Drawer Header)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, color: TVTheme.focusColor, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Quick Channel Guide',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: TVTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(
                      '${widget.playlist.length} CH',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TVTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: TVTheme.textMuted, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),

            // Channel Scroll List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.playlist.length,
                itemExtent: _itemHeight,
                itemBuilder: (context, index) {
                  final ch = widget.playlist[index];
                  final isCurrent = ch.id == widget.currentChannel.id;
                  final isFocused = _selectedIndex == index;
                  final liveProgram = EpgService.instance.getCurrentProgram(ch);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onChannelSelected(ch);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFocused
                            ? TVTheme.focusColor
                            : isCurrent
                                ? const Color(0xFF23252E)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isFocused
                              ? Colors.white
                              : isCurrent
                                  ? TVTheme.focusColor.withOpacity(0.7)
                                  : Colors.transparent,
                          width: isFocused ? 2 : 1,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: TVTheme.focusColor.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isFocused ? Colors.black87 : TVTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: ch.logo.isNotEmpty
                                ? (ch.logo.startsWith('assets/')
                                    ? Image.asset(ch.logo, fit: BoxFit.contain)
                                    : CachedNetworkImage(
                                        imageUrl: ch.logo,
                                        fit: BoxFit.contain,
                                        memCacheWidth: 200,
                                        memCacheHeight: 200,
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.live_tv_rounded,
                                          size: 18,
                                          color: TVTheme.focusColor,
                                        ),
                                      ))
                                : const Icon(Icons.live_tv_rounded, size: 18, color: TVTheme.focusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ch.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isFocused || isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isFocused
                                        ? Colors.black87
                                        : isCurrent
                                            ? Colors.white
                                            : TVTheme.textSecondary,
                                  ),
                                ),
                                if (liveProgram != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    liveProgram.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isFocused
                                          ? Colors.black54
                                          : TVTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFocused ? Colors.black87 : TVTheme.accentRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isFocused ? TVTheme.focusColor : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
