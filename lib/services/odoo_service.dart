import '../models/product.dart';

abstract class OdooService {
  Future<Product?> getProductByBarcode(String barcode);
  Future<bool> updateStock(int productId, double newQuantity);
}

class MockOdooService implements OdooService {
  final Map<String, Product> _mockDb = {
    '123456789': Product(id: 1, name: 'Sample Widget A', barcode: '123456789', qtyAvailable: 50.0, category: 'All / Components', uom: 'Units'),
    '987654321': Product(id: 2, name: 'Sample Gizmo B', barcode: '987654321', qtyAvailable: 15.0, category: 'All / Raw Materials', uom: 'Units'),
  };

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return _mockDb[barcode];
  }

  @override
  Future<bool> updateStock(int productId, double newQuantity) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    String? foundBarcode;
    for (var entry in _mockDb.entries) {
      if (entry.value.id == productId) {
        foundBarcode = entry.key;
        break;
      }
    }
    if (foundBarcode != null) {
      _mockDb[foundBarcode] = _mockDb[foundBarcode]!.copyWith(qtyAvailable: newQuantity);
      return true;
    }
    return false;
  }
}
