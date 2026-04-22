import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    if (provider.currentProduct != null) {
      _qtyController.text = provider.currentProduct!.qtyAvailable.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, {required String msg, required Color bg, required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    final product = provider.currentProduct;

    if (product == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.packageX, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No product selected', style: GoogleFonts.inter(color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: provider.isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          : Column(
              children: [
                // Dark gradient header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        children: [
                          // Custom app bar
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Adjust Inventory',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Product icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                            ),
                            child: const Icon(LucideIcons.package, size: 30, color: Color(0xFF60A5FA)),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            product.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Barcode chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.qrCode, size: 14, color: Colors.white54),
                                const SizedBox(width: 6),
                                Text(
                                  product.barcode,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (product.category != null || product.uom != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (product.category != null)
                                  _DarkChip(icon: LucideIcons.tag, label: product.category!),
                                if (product.category != null && product.uom != null)
                                  const SizedBox(width: 8),
                                if (product.uom != null)
                                  _DarkChip(icon: LucideIcons.ruler, label: product.uom!),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Light body
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Current Stock Card
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CURRENT STOCK',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${product.qtyAvailable}',
                                  style: GoogleFonts.inter(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (product.uom != null)
                                  Text(
                                    product.uom!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quantity Adjustment Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEW QUANTITY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _QtyButton(
                                      icon: LucideIcons.minus,
                                      onTap: () {
                                        final c = double.tryParse(_qtyController.text) ?? 0;
                                        if (c > 0) _qtyController.text = (c - 1).toString();
                                      },
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: TextField(
                                        controller: _qtyController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF1F5F9),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    _QtyButton(
                                      icon: LucideIcons.plus,
                                      onTap: () {
                                        final c = double.tryParse(_qtyController.text) ?? 0;
                                        _qtyController.text = (c + 1).toString();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Sync Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                final newQty = double.tryParse(_qtyController.text);
                                if (newQty != null) {
                                  await provider.updateQuantity(newQty);
                                  if (!context.mounted) return;
                                  if (provider.errorMessage != null) {
                                    _showSnack(context,
                                        msg: provider.errorMessage!,
                                        bg: const Color(0xFFEF4444),
                                        icon: LucideIcons.alertCircle);
                                  } else {
                                    _showSnack(context,
                                        msg: 'Stock synced successfully!',
                                        bg: const Color(0xFF10B981),
                                        icon: LucideIcons.checkCircle);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text('Sync to Odoo', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Back to Scan
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.scanLine, color: Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text('Back to Scan', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),
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

class _DarkChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
        ),
      ),
    );
  }
}
