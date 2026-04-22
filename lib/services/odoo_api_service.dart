import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'odoo_service.dart';

class OdooApiService implements OdooService {
  final String odooUrl;
  final String db;
  final String username;
  final String password;

  String? _sessionId;
  int? _uid;

  OdooApiService({
    required this.odooUrl,
    required this.db,
    required this.username,
    required this.password,
  });

  Future<bool> authenticate() async {
    if (_sessionId != null && _uid != null) return true;

    final url = Uri.parse('$odooUrl/web/session/authenticate');
    final payload = {
      'jsonrpc': '2.0',
      'params': {
        'db': db,
        'login': username,
        'password': password,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] != null) {
        throw Exception(jsonResponse['error']['data']['message']);
      }

      _uid = jsonResponse['result']['uid'];
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final sessionCookie = cookies
            .split(';')
            .firstWhere((c) => c.trim().startsWith('session_id='));
        _sessionId = sessionCookie.split('=')[1];
      }
      return true;
    } else {
      throw Exception('Failed to authenticate with Odoo');
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    await authenticate();

    final url = Uri.parse('$odooUrl/web/dataset/call_kw');
    final payload = {
      'jsonrpc': '2.0',
      'params': {
        'model': 'product.product',
        'method': 'search_read',
        'args': [
          [
            ['barcode', '=', barcode]
          ],
        ],
        'kwargs': {
          'fields': ['id', 'name', 'barcode', 'qty_available', 'categ_id', 'uom_id'],
          'limit': 1,
        }
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] != null) {
        throw Exception(jsonResponse['error']['data']['message']);
      }

      final records = jsonResponse['result'] as List;
      if (records.isNotEmpty) {
        return Product.fromJson(
          records.first as Map<String, dynamic>,
          fallbackBarcode: barcode,
        );
      }
    }
    return null;
  }

  Future<int> _getDefaultLocationId() async {
    final url = Uri.parse('$odooUrl/web/dataset/call_kw');
    final payload = {
      'jsonrpc': '2.0',
      'params': {
        'model': 'stock.warehouse',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['lot_stock_id'],
          'limit': 1,
        }
      }
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
      },
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] == null) {
        final records = jsonResponse['result'] as List;
        if (records.isNotEmpty) {
          final lotStockId = records.first['lot_stock_id'];
          if (lotStockId is List && lotStockId.isNotEmpty) {
            return lotStockId[0] as int;
          }
        }
      }
    }
    return 8; // fallback to 8 if not found
  }

  @override
  Future<bool> updateStock(int productId, double newQuantity) async {
    await authenticate();

    final locationId = await _getDefaultLocationId();
    final url = Uri.parse('$odooUrl/web/dataset/call_kw');

    // 1. Search for existing quant in ANY internal location
    var payload = {
      'jsonrpc': '2.0',
      'params': {
        'model': 'stock.quant',
        'method': 'search_read',
        'args': [
          [
            ['product_id', '=', productId],
            ['location_id.usage', '=', 'internal']
          ]
        ],
        'kwargs': {
          'fields': ['id'],
          'limit': 1
        }
      }
    };

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
      },
      body: jsonEncode(payload),
    );

    int? quantId;
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final result = jsonResponse['result'];
      if (result != null && result is List && result.isNotEmpty) {
        quantId = result.first['id'] as int;
      }
    }

    if (quantId != null) {
      // 2a. Update existing quant
      payload = {
        'jsonrpc': '2.0',
        'params': {
          'model': 'stock.quant',
          'method': 'write',
          'args': [
            [quantId],
            {'inventory_quantity': newQuantity}
          ],
          'kwargs': {}
        }
      };
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
        },
        body: jsonEncode(payload),
      );
    } else {
      // 2b. Create new quant
      payload = {
        'jsonrpc': '2.0',
        'params': {
          'model': 'stock.quant',
          'method': 'create',
          'args': [
            {
              'product_id': productId,
              'location_id': locationId,
              'inventory_quantity': newQuantity,
            }
          ],
          'kwargs': {}
        }
      };
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] != null) {
          throw Exception(jsonResponse['error']['data']['message']);
        }
        quantId = jsonResponse['result'] as int?;
      }
    }

    if (quantId != null) {
      // 3. Apply the inventory update
      payload = {
        'jsonrpc': '2.0',
        'params': {
          'model': 'stock.quant',
          'method': 'action_apply_inventory',
          'args': [
            [quantId]
          ],
          'kwargs': {}
        }
      };
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null) 'Cookie': 'session_id=$_sessionId',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['error'] != null) {
          throw Exception(jsonResponse['error']['data']['message']);
        }
        return true;
      }
    }

    return false;
  }
}
