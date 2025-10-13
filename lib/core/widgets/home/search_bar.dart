import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String placeholder;
  final Function(String)? onChanged;
  final Function()? onTap;

  const CustomSearchBar({
    super.key,
    this.placeholder = "Search destinations, tours...",
    this.onChanged,
    this.onTap,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      Navigator.pushNamed(
        context, 
        '/search',
        arguments: {'query': value.trim()},
      );
    }
  }

  void _handleTap() {
    widget.onTap?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                onSubmitted: _handleSubmitted,
                onTap: _handleTap,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: Colors.blue,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}