import 'package:flutter/material.dart';

class AnimatedPetWidget extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final bool animate;

  const AnimatedPetWidget({
    super.key,
    this.imageUrl,
    this.size = 120,
    this.animate = true,
  });

  @override
  State<AnimatedPetWidget> createState() => _AnimatedPetWidgetState();
}

class _AnimatedPetWidgetState extends State<AnimatedPetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Icon(Icons.pets, size: 60, color: Colors.grey),
      );
    }

    final petWidget = Image.network(
      widget.imageUrl!,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.pets,
        size: widget.size * 0.6,
        color: Colors.grey,
      ),
    );

    if (!widget.animate) return petWidget;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: petWidget,
    );
  }
}