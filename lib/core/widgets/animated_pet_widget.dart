import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import 'package:gif/gif.dart';

class AnimatedPetWidget extends StatefulWidget {
  final String? imageUrl;
  final String? soundUrl; // add this
  final double size;
  final bool animate;
  final bool interactive;

  const AnimatedPetWidget({
    super.key,
    this.imageUrl,
    this.soundUrl, // add this
    this.size = 120,
    this.animate = true,
    this.interactive = false,
  });

  @override
  State<AnimatedPetWidget> createState() => _AnimatedPetWidgetState();
}

class _AnimatedPetWidgetState extends State<AnimatedPetWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bounceController;
  GifController? _gifController;
  late Animation<double> _floatAnimation;
  late Animation<double> _bounceAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isBouncing = false;
  String? _speechBubble;

  static const List<String> _messages = [
    "Let's study! 📚",
    "You're doing great! ⭐",
    "Keep it up! 💪",
    "I believe in you! 🌟",
    "You're so smart! 🧠",
    "Learning is fun! 🎉",
    "Go go go! 🚀",
    "You're my hero! 🦸",
    "Amazing! Keep going! ✨",
    "We can do this! 🎯",
  ];

  bool get _isGif =>
      widget.imageUrl != null &&
          widget.imageUrl!.toLowerCase().contains('.gif');

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
          parent: _floatController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
          parent: _bounceController, curve: Curves.elasticOut),
    );

    if (_isGif) {
      _gifController = GifController(vsync: this);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    _gifController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (!widget.interactive || _isBouncing) return;

    setState(() {
      _isBouncing = true;
      _speechBubble =
      _messages[DateTime.now().millisecond % _messages.length];
    });

    // Play sound from URL or fallback to asset
    try {
      if (widget.soundUrl != null && widget.soundUrl!.isNotEmpty) {
        await _audioPlayer.play(UrlSource(widget.soundUrl!));
      } else {
        await _audioPlayer.play(AssetSource('sounds/pet_sound.wav'));
      }
    } catch (_) {}

    await _bounceController.forward();
    await _bounceController.reverse();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isBouncing = false;
        _speechBubble = null;
      });
    }
  }

  Widget _buildPetImage() {
    if (widget.imageUrl == null) {
      return Icon(Icons.pets,
          size: widget.size * 0.6, color: Colors.grey);
    }

    if (_isGif && _gifController != null) {
      return Gif(
        image: NetworkImage(widget.imageUrl!),
        controller: _gifController!,
        height: widget.size,
        width: widget.size,
        fit: BoxFit.contain,
        autostart: Autostart.loop,
        fps: 15,
        placeholder: (context) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        onFetchCompleted: () {
          _gifController?.repeat();
        },
      );
    }

    return Image.network(
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
  }

  @override
  Widget build(BuildContext context) {
    Widget petImage = _buildPetImage();

    // Apply float
    if (widget.animate && !_isBouncing) {
      petImage = AnimatedBuilder(
        animation: _floatAnimation,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        ),
        child: petImage,
      );
    }

    // Apply bounce
    if (_isBouncing) {
      petImage = AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, child) => Transform.scale(
          scale: _bounceAnimation.value,
          child: child,
        ),
        child: petImage,
      );
    }

    return GestureDetector(
      onTap: widget.interactive ? _onTap : null,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (_speechBubble != null)
            Positioned(
              top: -50,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.petsColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _speechBubble!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          petImage,
        ],
      ),
    );
  }
}