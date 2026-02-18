import 'package:flutter/material.dart';

class VideoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const VideoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      padding: const EdgeInsets.all(6),
      style: IconButton.styleFrom(
        minimumSize: Size.zero,
        backgroundColor: Colors.black26,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
