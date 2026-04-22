class Product {
  final int id;
  final String name;
  final String barcode;
  final double qtyAvailable;
  final String? category;
  final String? uom;
  final DateTime scannedAt;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.qtyAvailable,
    this.category,
    this.uom,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json, {String? fallbackBarcode}) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      barcode: (json['barcode'] ?? fallbackBarcode ?? '') as String,
      qtyAvailable: (json['qty_available'] ?? 0).toDouble(),
      category: json['categ_id'] is List ? json['categ_id'][1] as String? : null,
      uom: json['uom_id'] is List ? json['uom_id'][1] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'qty_available': qtyAvailable,
      if (category != null) 'category': category,
      if (uom != null) 'uom': uom,
    };
  }

  Product copyWith({double? qtyAvailable}) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      qtyAvailable: qtyAvailable ?? this.qtyAvailable,
      category: category,
      uom: uom,
      scannedAt: scannedAt,
    );
  }
}
