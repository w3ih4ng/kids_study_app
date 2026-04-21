import 'package:flutter/material.dart';

class PinScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onSuccess;

  const PinScreen({
    super.key,
    required this.correctPin,
    required this.onSuccess,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';

  void _onKeyTap(String digit) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += digit);
      if (_enteredPin.length == 4) _verify();
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(
        () => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1),
      );
    }
  }

  void _verify() {
    if (_enteredPin == widget.correctPin) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Try again.')),
      );
      setState(() => _enteredPin = '');
    }
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _onKeyTap(label),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Access')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Enter 4-digit PIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _enteredPin.length
                        ? Colors.indigo
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            // Number pad
            for (var row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildKey(d),
                        ),
                      )
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 96),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildKey('0'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ), // ← add this wrapper
                    child: GestureDetector(
                      onTap: _onDelete,
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          Icons.backspace_outlined,
                          color: Colors.indigo,
                          size: 28,
                        ),
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
