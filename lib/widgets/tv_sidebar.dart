import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/language.dart';
import '../theme/tv_theme.dart';

class TVSidebar extends StatelessWidget {
  final List<LanguageCategory> categories;
  final String selectedCategory;
  final String selectedGenre;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onGenreSelected;

  const TVSidebar({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    this.selectedGenre = 'all',
    required this.onCategorySelected,
    required this.onGenreSelected,
  }) : super(key: key);

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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isLangSelected = cat.code == selectedCategory;
                final isAllGenre = selectedGenre == 'all';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TVSidebarItem(
                      category: cat,
                      isSelected: isLangSelected && isAllGenre,
                      isExpanded: isLangSelected && cat.genres.isNotEmpty,
                      onSelect: () => onCategorySelected(cat.code),
                    ),
                    if (isLangSelected && cat.genres.isNotEmpty) ...[
                      for (final genre in cat.genres)
                        _TVGenreItem(
                          genre: genre,
                          isSelected: selectedGenre == genre.code,
                          onSelect: () => onGenreSelected(genre.code),
                        ),
                    ],
                  ],
                );
              },
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
}

class _TVSidebarItem extends StatefulWidget {
  final LanguageCategory category;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onSelect;

  const _TVSidebarItem({
    Key? key,
    required this.category,
    required this.isSelected,
    this.isExpanded = false,
    required this.onSelect,
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
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
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
                  widget.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
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
  final GenreCategory genre;
  final bool isSelected;
  final VoidCallback onSelect;

  const _TVGenreItem({
    Key? key,
    required this.genre,
    required this.isSelected,
    required this.onSelect,
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
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
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
