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

  @override
  void dispose() {
    _controller.dispose();
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
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                onSubmitted: _handleSubmitted,
                onTap: () {},
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
