import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: secondaryColor)),
          ],
        ],
      ),
    );
  }
}
