import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/friend_service.dart';
import '../../core/widgets/app_snackbar.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final scannedId = barcode!.rawValue!;
    final child = context.read<ChildProvider>().activeChild!;

    if (scannedId == child.id) {
      AppSnackbar.warning(context, "That's your own QR code!");
      return;
    }

    setState(() => _isProcessing = true);
    controller.stop();

    try {
      final check = await Supabase.instance.client
          .from('children_public')
          .select('id, nickname')
          .eq('id', scannedId)
          .limit(1);

      if ((check as List).isEmpty) {
        if (mounted) {
          AppSnackbar.error(context, 'Invalid QR code. Please try again.');
          setState(() => _isProcessing = false);
          controller.start();
        }
        return;
      }

      final already = await FriendService.isFriend(
        childId: child.id,
        friendId: scannedId,
      );

      if (already) {
        if (mounted) {
          AppSnackbar.info(context, 'You are already friends!');
          Navigator.pop(context);
        }
        return;
      }

      // Check if request already sent
      final existingStatus = await FriendService.getRequestStatus(
        senderId: child.id,
        receiverId: scannedId,
      );

      if (existingStatus == 'pending') {
        if (mounted) {
          AppSnackbar.info(context, 'Friend request already sent!');
          Navigator.pop(context);
        }
        return;
      }

      await FriendService.sendRequest(
        senderId: child.id,
        receiverId: scannedId,
      );

      if (mounted) {
        AppSnackbar.success(context, 'Friend request sent! 🎉');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Something went wrong. Please try again.');
        setState(() => _isProcessing = false);
        controller.start();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point camera at your friend\'s QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}