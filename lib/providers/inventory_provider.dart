import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/odoo_service.dart';

class InventoryProvider with ChangeNotifier {
  final OdooService _odooService;

  Product? _currentProduct;
  bool _isLoading = false;
  String? _errorMessage;
  final List<Product> _scanHistory = [];

  InventoryProvider(this._odooService);

  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get scanHistory => List.unmodifiable(_scanHistory);
  int get totalScans => _scanHistory.length;

  Future<void> scanBarcode(String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _odooService.getProductByBarcode(barcode);
      if (product != null) {
        _currentProduct = product;
        _scanHistory.insert(0, product);
      } else {
        _errorMessage = 'Product not found for barcode: $barcode';
        _currentProduct = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to scan barcode: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(double newQuantity) async {
    if (_currentProduct == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _odooService.updateStock(_currentProduct!.id, newQuantity);
      if (success) {
        _currentProduct = _currentProduct!.copyWith(qtyAvailable: newQuantity);
      } else {
        _errorMessage = 'Failed to update stock in ERP.';
      }
    } catch (e) {
      _errorMessage = 'Error updating stock: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentProduct() {
    _currentProduct = null;
    _errorMessage = null;
    notifyListeners();
  }
}
