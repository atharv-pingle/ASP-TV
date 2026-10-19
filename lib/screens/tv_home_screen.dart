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
  final FocusNode _searchBarContainerFocusNode = FocusNode();
  final FocusNode _firstCardFocusNode = FocusNode(debugLabel: 'FirstCardFocusNode');
  bool _isSearchEditing = false;
  bool _isSearchContainerFocused = false;
  DateTime? _lastBackPressTime;
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
    _searchBarContainerFocusNode.dispose();
    _firstCardFocusNode.dispose();
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

  void _enterSearchEditing() {
    setState(() {
      _isSearchEditing = true;
    });
    _searchFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  void _exitSearchEditing() {
    setState(() {
      _isSearchEditing = false;
    });
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _searchBarContainerFocusNode.requestFocus();
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
        if (_isSearchEditing) {
          _exitSearchEditing();
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

        // Double-press Back to exit app (protects against accidental TV remote exit)
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Press Back again to exit ASP TV',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.only(bottom: 24, left: 100, right: 100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: TVTheme.focusColor.withOpacity(0.6), width: 1.5),
              ),
            ),
          );
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
              onNavigateToContent: () {
                _firstCardFocusNode.requestFocus();
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
                        // Active category title & badge (Protected against overflow)
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                activeCat.icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  activeCat.code == 'fav'
                                      ? 'Favorites & Recents'
                                      : activeCat.code == 'all'
                                          ? 'All Channels'
                                          : service.selectedCategory == 'all'
                                              ? '${activeCat.name} Channels'
                                              : '${activeCat.name} ${service.selectedCategory == 'news' ? 'News' : service.selectedCategory == 'movies' ? 'Movies' : service.selectedCategory == 'music' ? 'Music' : 'Entertainment'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: TVTheme.textPrimary,
                                  ),
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
                                  activeCat.code == 'fav'
                                      ? '${service.favoriteChannels.length} Fav • ${recents.length} Recent'
                                      : '${channels.length} Channels',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: TVTheme.focusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Fixed Right Controls: Search Bar + Clock
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search Bar with Remote-Aware Focus & Escaping (TV Focus Button Pattern)
                            Focus(
                              focusNode: _searchBarContainerFocusNode,
                              onFocusChange: (focused) {
                                setState(() {
                                  _isSearchContainerFocused = focused;
                                });
                              },
                              onKeyEvent: (node, event) {
                                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                                final key = event.logicalKey;

                                if (_isSearchEditing) {
                                  if (key == LogicalKeyboardKey.escape ||
                                      key == LogicalKeyboardKey.goBack ||
                                      key.keyId == 0x00100000004) {
                                    _exitSearchEditing();
                                    return KeyEventResult.handled;
                                  }
                                  if (key == LogicalKeyboardKey.arrowDown) {
                                    _exitSearchEditing();
                                    _firstCardFocusNode.requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                }

                                // Navigation Mode (not editing)
                                if (key == LogicalKeyboardKey.select ||
                                    key == LogicalKeyboardKey.enter ||
                                    key == LogicalKeyboardKey.numpadEnter ||
                                    key == LogicalKeyboardKey.space ||
                                    key == LogicalKeyboardKey.gameButtonA ||
                                    key.keyId == 0x00100000017 ||
                                    key.keyId == 0x00100000042) {
                                  _enterSearchEditing();
                                  return KeyEventResult.handled;
                                }

                                if (key == LogicalKeyboardKey.arrowDown) {
                                  _firstCardFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }

                                if (key == LogicalKeyboardKey.arrowLeft) {
                                  FocusScope.of(context).previousFocus();
                                  return KeyEventResult.handled;
                                }

                                return KeyEventResult.ignored;
                              },
                          child: GestureDetector(
                            onTap: _enterSearchEditing,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 280,
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _isSearchContainerFocused
                                    ? TVTheme.focusColor.withOpacity(0.18)
                                    : TVTheme.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isSearchContainerFocused
                                      ? Colors.white
                                      : (_isSearchEditing ? TVTheme.focusColor : Colors.white12),
                                  width: _isSearchContainerFocused ? 2 : 1,
                                ),
                                boxShadow: _isSearchContainerFocused
                                    ? [
                                        BoxShadow(
                                          color: TVTheme.focusColor.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: _isSearchContainerFocused ? Colors.white : TVTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _isSearchEditing
                                        ? TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            textInputAction: TextInputAction.search,
                                            onSubmitted: (_) {
                                              _exitSearchEditing();
                                              FocusScope.of(context).nextFocus();
                                            },
                                            onChanged: (val) => service.setSearchQuery(val),
                                            style: const TextStyle(fontSize: 14, color: Colors.white),
                                            decoration: const InputDecoration(
                                              hintText: 'Type channel name...',
                                              hintStyle: TextStyle(fontSize: 13, color: TVTheme.textMuted),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          )
                                        : Text(
                                            _searchController.text.isNotEmpty
                                                ? _searchController.text
                                                : 'Search channels...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _searchController.text.isNotEmpty
                                                  ? Colors.white
                                                  : TVTheme.textMuted,
                                              fontWeight: _searchController.text.isNotEmpty
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        service.setSearchQuery('');
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.clear_rounded, size: 16, color: TVTheme.textMuted),
                                      ),
                                    )
                                  else if (_isSearchContainerFocused && !_isSearchEditing)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                ],
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
                  ],
                ),
              ),

              // Unified Smooth-Scrolling Content Area
              Expanded(
                child: FocusTraversalGroup(
                  child: CustomScrollView(
                      slivers: [
                        if (service.selectedLanguage == 'fav' && service.searchQuery.isEmpty) ...[
                          // SECTION 1: Favorite Channels Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Favorite Channels',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: TVTheme.textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${service.favoriteChannels.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: TVTheme.focusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (service.favoriteChannels.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.star_border_rounded, size: 28, color: TVTheme.textMuted),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'No favorite channels yet. Long-press OK on any channel to add it to your Favorites.',
                                          style: TextStyle(fontSize: 13, color: TVTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.25,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final channel = service.favoriteChannels[index];
                                    return TVChannelCard(
                                      channel: channel,
                                      autoFocus: index == 0,
                                      focusNode: index == 0 ? _firstCardFocusNode : null,
                                      onSelect: () => _openPlayer(channel, service.favoriteChannels),
                                      onToggleFavorite: () => service.toggleFavorite(channel),
                                    );
                                  },
                                  childCount: service.favoriteChannels.length,
                                ),
                              ),
                            ),

                          // SECTION 2: Recently Watched Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 20, color: TVTheme.focusColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recently Watched',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: TVTheme.textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${recents.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: TVTheme.focusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (recents.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.history_toggle_off_rounded, size: 28, color: TVTheme.textMuted),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'No recently watched channels yet. Watch any channel and it will appear here for fast access.',
                                          style: TextStyle(fontSize: 13, color: TVTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.25,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final channel = recents[index];
                                    return TVChannelCard(
                                      channel: channel,
                                      focusNode: (service.favoriteChannels.isEmpty && index == 0)
                                          ? _firstCardFocusNode
                                          : null,
                                      onSelect: () => _openPlayer(channel, recents),
                                      onToggleFavorite: () => service.toggleFavorite(channel),
                                    );
                                  },
                                  childCount: recents.length,
                                ),
                              ),
                            ),
                        ] else ...[
                          // For all other categories & active Search:
                          // Clean channel grid only! No top recent shelf pushing content down!
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
                                      'No channels match "${service.searchQuery}"',
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
                                      autoFocus: index == 0,
                                      focusNode: index == 0 ? _firstCardFocusNode : null,
                                      onSelect: () => _openPlayer(channel, channels),
                                      onToggleFavorite: () => service.toggleFavorite(channel),
                                    );
                                  },
                                  childCount: channels.length,
                                ),
                              ),
                            ),
                        ],
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
    );
  }
}

