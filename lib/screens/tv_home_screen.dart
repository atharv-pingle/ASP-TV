import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/channel_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_channel_card.dart';
import '../widgets/tv_sidebar.dart';
import 'tv_player_screen.dart';

class TVHomeScreen extends StatefulWidget {
  final ChannelService channelService;

  const TVHomeScreen({Key? key, required this.channelService}) : super(key: key);

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _currentTime = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
    widget.channelService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _updateClock() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute $ampm';
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    widget.channelService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _openPlayer(Channel channel, List<Channel> currentList) {
    widget.channelService.recordWatchedChannel(channel);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TVPlayerScreen(
          initialChannel: channel,
          playlist: currentList,
          channelService: widget.channelService,
        ),
      ),
    );
  }

  void _unfocusSearch() {
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.channelService;

    if (service.isLoading) {
      return const Scaffold(
        backgroundColor: TVTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: TVTheme.focusColor),
              SizedBox(height: 16),
              Text(
                'Loading Indian News Channels...',
                style: TextStyle(color: TVTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final channels = service.filteredChannels;
    final categories = service.categoriesWithCounts;
    final activeCat = categories.firstWhere(
      (c) => c.code == service.selectedLanguage,
      orElse: () => categories.first,
    );
    final recents = service.recentChannels;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _unfocusSearch();
          return;
        }
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          service.setSearchQuery('');
          return;
        }
        if (service.selectedLanguage != 'all') {
          service.selectLanguage('all');
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: TVTheme.background,
        body: Row(
          children: [
            // Left Navigation Rail for Remote Control
            TVSidebar(
              categories: categories,
              selectedCategory: service.selectedLanguage,
              selectedGenre: service.selectedCategory,
              onCategorySelected: (catCode) {
                service.selectLanguage(catCode);
              },
              onGenreSelected: (genreCode) {
                service.selectCategory(genreCode);
              },
            ),

            // Main TV Screen Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top TV App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    color: TVTheme.background,
                    child: Row(
                      children: [
                        // Active category title & badge
                        Row(
                          children: [
                            Text(
                              activeCat.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              activeCat.code == 'fav'
                                  ? 'Favorite Channels'
                                  : activeCat.code == 'all'
                                      ? 'All Channels'
                                      : service.selectedCategory == 'all'
                                          ? '${activeCat.name} Channels'
                                          : '${activeCat.name} ${service.selectedCategory == 'news' ? 'News' : service.selectedCategory == 'movies' ? 'Movies' : 'Entertainment'}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: TVTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TVTheme.focusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TVTheme.focusColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                '${channels.length} Channels',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TVTheme.focusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Search Bar with Remote-Aware Focus & Escaping
                        Focus(
                          onKeyEvent: (node, event) {
                            if (event is! KeyDownEvent) return KeyEventResult.ignored;
                            final key = event.logicalKey;

                            // TV Back / Escape key: exit search input area cleanly
                            if (key == LogicalKeyboardKey.escape ||
                                key == LogicalKeyboardKey.goBack ||
                                key.keyId == 0x00100000004) {
                              _unfocusSearch();
                              return KeyEventResult.handled;
                            }

                            // Down arrow: exit search to channel grid or recents
                            if (key == LogicalKeyboardKey.arrowDown) {
                              _unfocusSearch();
                              FocusScope.of(context).nextFocus();
                              return KeyEventResult.handled;
                            }

                            // Left arrow at start: return to sidebar
                            if (key == LogicalKeyboardKey.arrowLeft &&
                                _searchController.selection.baseOffset <= 0) {
                              _unfocusSearch();
                              FocusScope.of(context).previousFocus();
                              return KeyEventResult.handled;
                            }

                            return KeyEventResult.ignored;
                          },
                          child: SizedBox(
                            width: 260,
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _unfocusSearch(),
                              onChanged: (val) => service.setSearchQuery(val),
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search channel...',
                                hintStyle: const TextStyle(fontSize: 13, color: TVTheme.textMuted),
                                prefixIcon: const Icon(Icons.search, size: 18, color: TVTheme.textSecondary),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16, color: TVTheme.textMuted),
                                        onPressed: () {
                                          _searchController.clear();
                                          service.setSearchQuery('');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: TVTheme.cardBackground,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: TVTheme.focusColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Clock
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: TVTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _currentTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TVTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unified Smooth-Scrolling Content Area
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // Recently Watched Section (Moves naturally upward with scrolling)
                        if (service.searchQuery.isEmpty && recents.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.history_rounded, size: 16, color: TVTheme.focusColor),
                                      SizedBox(width: 6),
                                      Text(
                                        'Recently Watched',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: TVTheme.textPrimary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 78,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recents.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final ch = recents[index];
                                        return _TVRecentChannelCard(
                                          channel: ch,
                                          onSelect: () => _openPlayer(ch, recents),
                                          onToggleFavorite: () => service.toggleFavorite(ch),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Channel Grid or Empty State
                        if (channels.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tv_off_rounded, size: 64, color: TVTheme.textMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    service.selectedLanguage == 'fav'
                                        ? 'No favorite channels yet.\nPress and hold or click the star on any channel to add it.'
                                        : 'No channels match "${service.searchQuery}"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: TVTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, // 4-column TV grid
                                childAspectRatio: 1.25,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final channel = channels[index];
                                  return TVChannelCard(
                                    channel: channel,
                                    autoFocus: index == 0 && recents.isEmpty,
                                    onSelect: () => _openPlayer(channel, channels),
                                    onToggleFavorite: () => service.toggleFavorite(channel),
                                  );
                                },
                                childCount: channels.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TVRecentChannelCard extends StatefulWidget {
  final Channel channel;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;

  const _TVRecentChannelCard({
    Key? key,
    required this.channel,
    required this.onSelect,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<_TVRecentChannelCard> createState() => _TVRecentChannelCardState();
}

class _TVRecentChannelCardState extends State<_TVRecentChannelCard> {
  bool _isFocused = false;
  Timer? _longPressTimer;

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
        key.keyId == 0x00100000042; // KEYCODE_ENTER
  }

  Widget _buildLogo() {
    final logo = widget.channel.logo;
    if (logo.isNotEmpty) {
      if (logo.startsWith('assets/')) {
        return Image.asset(
          logo,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.live_tv_rounded, size: 24, color: TVTheme.focusColor),
        );
      }
      return CachedNetworkImage(
        imageUrl: logo,
        fit: BoxFit.contain,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 12; Android TV; Build/STT2.220920.015) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        errorWidget: (_, __, ___) => const Icon(Icons.live_tv_rounded, size: 24, color: TVTheme.focusColor),
      );
    }
    return const Icon(Icons.live_tv_rounded, size: 24, color: TVTheme.focusColor);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && _isSelectKey(event.logicalKey)) {
          _longPressTimer?.cancel();
          _longPressTimer = Timer(const Duration(milliseconds: 600), () {
            widget.onToggleFavorite();
          });
          return KeyEventResult.handled;
        } else if (event is KeyUpEvent && _isSelectKey(event.logicalKey)) {
          if (_longPressTimer != null && _longPressTimer!.isActive) {
            _longPressTimer!.cancel();
            widget.onSelect();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onToggleFavorite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isFocused ? TVTheme.cardFocusBackground : TVTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused ? TVTheme.focusColor : Colors.white.withOpacity(0.08),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: TVTheme.focusColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: _buildLogo(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.channel.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500,
                    color: _isFocused ? Colors.white : TVTheme.textPrimary,
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

