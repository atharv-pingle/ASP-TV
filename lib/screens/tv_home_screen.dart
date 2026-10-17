import 'dart:async';
import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: TVTheme.background,
      body: Row(
        children: [
          // Left Navigation Rail for Remote Control
          TVSidebar(
            categories: categories,
            selectedCategory: service.selectedLanguage,
            onCategorySelected: (catCode) {
              service.selectLanguage(catCode);
            },
          ),

          // Main TV Screen Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top TV App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                    : '${activeCat.name} News',
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

                      // Search Bar
                      SizedBox(
                        width: 260,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
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

                // Channels Grid
                Expanded(
                  child: channels.isEmpty
                      ? Center(
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
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // 4-column TV grid
                            childAspectRatio: 1.25,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            final channel = channels[index];
                            return TVChannelCard(
                              channel: channel,
                              autoFocus: index == 0,
                              onSelect: () => _openPlayer(channel, channels),
                              onToggleFavorite: () => service.toggleFavorite(channel),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
