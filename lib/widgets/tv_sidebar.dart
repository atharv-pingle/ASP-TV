import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/language.dart';
import '../theme/tv_theme.dart';

class TVSidebar extends StatefulWidget {
  final List<LanguageCategory> categories;
  final String selectedCategory;
  final String selectedGenre;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onGenreSelected;
  final VoidCallback? onNavigateToContent;

  const TVSidebar({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    this.selectedGenre = 'all',
    required this.onCategorySelected,
    required this.onGenreSelected,
    this.onNavigateToContent,
  }) : super(key: key);

  @override
  State<TVSidebar> createState() => _TVSidebarState();
}

class _TVSidebarState extends State<TVSidebar> {
  final Map<String, FocusNode> _nodes = {};

  FocusNode _getNode(String key) {
    return _nodes.putIfAbsent(key, () => FocusNode(debugLabel: key));
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: TVTheme.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ASP TV Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: TVTheme.focusColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.live_tv_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASP TV',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Live Television',
                      style: TextStyle(
                        fontSize: 11,
                        color: TVTheme.focusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Categories & Language List with Expandable Genres
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.categories.length; i++) ...[
                    _buildCategoryBlock(i),
                  ],
                ],
              ),
            ),
          ),

          // Remote Hint
          const Divider(color: Colors.white10, height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 14, color: TVTheme.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'D-Pad to Move • OK to Open',
                    style: TextStyle(
                      fontSize: 11,
                      color: TVTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBlock(int catIndex) {
    final cat = widget.categories[catIndex];
    final isLangSelected = cat.code == widget.selectedCategory;
    final isAllGenre = widget.selectedGenre == 'all';
    final hasGenres = cat.genres.isNotEmpty;
    final isExpanded = isLangSelected && hasGenres;

    final catNode = _getNode('cat_${cat.code}');

    // Target for down from category: first genre if expanded, or next category
    VoidCallback? onDown;
    if (isExpanded) {
      onDown = () {
        final firstGenreNode = _getNode('genre_${cat.code}_${cat.genres.first.code}');
        firstGenreNode.requestFocus();
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TVSidebarItem(
          focusNode: catNode,
          category: cat,
          isSelected: isLangSelected && isAllGenre,
          isExpanded: isExpanded,
          onSelect: () => widget.onCategorySelected(cat.code),
          onDownToSubcategory: onDown,
          onRightToContent: widget.onNavigateToContent,
        ),
        if (isExpanded) ...[
          for (int g = 0; g < cat.genres.length; g++)
            _buildGenreItem(cat, catIndex, g),
        ],
      ],
    );
  }

  Widget _buildGenreItem(LanguageCategory cat, int catIndex, int genreIndex) {
    final genre = cat.genres[genreIndex];
    final isSelected = widget.selectedGenre == genre.code;
    final genreNode = _getNode('genre_${cat.code}_${genre.code}');

    // If first genre, arrowUp goes to parent category
    VoidCallback? onUp;
    if (genreIndex == 0) {
      onUp = () {
        _getNode('cat_${cat.code}').requestFocus();
      };
    } else {
      onUp = () {
        _getNode('genre_${cat.code}_${cat.genres[genreIndex - 1].code}').requestFocus();
      };
    }

    // If last genre, arrowDown goes to next category
    VoidCallback? onDown;
    if (genreIndex == cat.genres.length - 1) {
      if (catIndex + 1 < widget.categories.length) {
        onDown = () {
          final nextCat = widget.categories[catIndex + 1];
          _getNode('cat_${nextCat.code}').requestFocus();
        };
      }
    } else {
      onDown = () {
        _getNode('genre_${cat.code}_${cat.genres[genreIndex + 1].code}').requestFocus();
      };
    }

    return _TVGenreItem(
      focusNode: genreNode,
      genre: genre,
      isSelected: isSelected,
      onSelect: () => widget.onGenreSelected(genre.code),
      onUp: onUp,
      onDown: onDown,
      onRightToContent: widget.onNavigateToContent,
    );
  }
}

class _TVSidebarItem extends StatefulWidget {
  final FocusNode focusNode;
  final LanguageCategory category;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onSelect;
  final VoidCallback? onDownToSubcategory;
  final VoidCallback? onRightToContent;

  const _TVSidebarItem({
    Key? key,
    required this.focusNode,
    required this.category,
    required this.isSelected,
    this.isExpanded = false,
    required this.onSelect,
    this.onDownToSubcategory,
    this.onRightToContent,
  }) : super(key: key);

  @override
  State<_TVSidebarItem> createState() => _TVSidebarItemState();
}

class _TVSidebarItemState extends State<_TVSidebarItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.arrowDown &&
              widget.isExpanded &&
              widget.onDownToSubcategory != null) {
            widget.onDownToSubcategory!();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowRight &&
              widget.onRightToContent != null) {
            widget.onRightToContent!();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key.keyId == 0x00100000017 ||
              key.keyId == 0x00100000042) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isFocused
                ? TVTheme.focusColor
                : active
                    ? TVTheme.cardFocusBackground
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : active
                      ? TVTheme.focusColor.withOpacity(0.6)
                      : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: TVTheme.focusColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(
                widget.category.icon,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _isFocused || active
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _isFocused
                        ? Colors.black87
                        : active
                            ? Colors.white
                            : TVTheme.textSecondary,
                  ),
                ),
              ),
              if (widget.category.genres.isNotEmpty)
                Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 16,
                  color: _isFocused ? Colors.black87 : TVTheme.textMuted,
                ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isFocused
                      ? Colors.black26
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.category.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isFocused ? Colors.black87 : TVTheme.textMuted,
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

class _TVGenreItem extends StatefulWidget {
  final FocusNode focusNode;
  final GenreCategory genre;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onRightToContent;

  const _TVGenreItem({
    Key? key,
    required this.focusNode,
    required this.genre,
    required this.isSelected,
    required this.onSelect,
    this.onUp,
    this.onDown,
    this.onRightToContent,
  }) : super(key: key);

  @override
  State<_TVGenreItem> createState() => _TVGenreItemState();
}

class _TVGenreItemState extends State<_TVGenreItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.arrowUp && widget.onUp != null) {
            widget.onUp!();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowDown && widget.onDown != null) {
            widget.onDown!();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowRight &&
              widget.onRightToContent != null) {
            widget.onRightToContent!();
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key.keyId == 0x00100000017 ||
              key.keyId == 0x00100000042) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(left: 20, right: 4, top: 2, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _isFocused
                ? TVTheme.focusColor
                : active
                    ? TVTheme.cardFocusBackground
                    : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : active
                      ? TVTheme.focusColor
                      : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.genre.icon,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.genre.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isFocused || active
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _isFocused
                        ? Colors.black87
                        : active
                            ? Colors.white
                            : TVTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _isFocused
                      ? Colors.black26
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.genre.count}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isFocused ? Colors.black87 : TVTheme.textMuted,
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
