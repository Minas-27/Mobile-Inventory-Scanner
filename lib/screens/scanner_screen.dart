import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'product_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchEnabled = false;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_isProcessing) return;
              _isProcessing = true; // Set immediately, no setState needed for guard

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String barcode = barcodes.first.rawValue!;
                
                HapticFeedback.mediumImpact();
                
                // Stop camera immediately to prevent duplicate fires
                _controller.stop();
                setState(() {});
                
                final provider = Provider.of<InventoryProvider>(context, listen: false);
                await provider.scanBarcode(barcode);

                if (!context.mounted) return;

                if (provider.errorMessage != null) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(provider.errorMessage!)),
                        ],
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  _controller.start();
                } else if (provider.currentProduct != null) {
                  // Hide overlay BEFORE navigating
                  setState(() => _isProcessing = false);
                  // Navigate and WAIT for user to come back
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider<InventoryProvider>.value(
                        value: provider,
                        child: const ProductDetailScreen(),
                      ),
                    ),
                  );
                  // User came back — clear state and add cooldown
                  // so the camera doesn't immediately re-scan the same barcode
                  if (mounted) {
                    provider.clearCurrentProduct();
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) {
                      _controller.start();
                    }
                  }
                } else {
                  setState(() => _isProcessing = false);
                  _controller.start();
                }
              } else {
                _isProcessing = false;
              }
            },
          ),
          
          // Immersive Cutout Overlay
          CustomPaint(
            size: Size.infinite,
            painter: OverlayPainter(
              overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.85),
            ),
          ),
          // White Cutout Border + Animated Scan Line
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, child) {
                      final cutoutSize = MediaQuery.of(context).size.width * 0.7;
                      final lineY = _scanLineController.value * (cutoutSize - 40) + 20;
                      return Positioned(
                        top: lineY,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF3B82F6).withValues(alpha: 0.8),
                                const Color(0xFF3B82F6),
                                const Color(0xFF3B82F6).withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(
                  LucideIcons.chevronLeft,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Flashlight Toggle Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: GestureDetector(
              onTap: () async {
                await _controller.toggleTorch();
                setState(() => _torchEnabled = !_torchEnabled);
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _torchEnabled ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(
                  _torchEnabled ? LucideIcons.zap : LucideIcons.zapOff,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Floating instructions
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.focus, color: Color(0xFF1E293B), size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Point camera at barcode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Looking up product...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  final Color overlayColor;

  OverlayPainter({required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final holeSize = size.width * 0.7;
    
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2),
                width: holeSize,
                height: holeSize,
              ),
              const Radius.circular(24),
            ),
          ),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
