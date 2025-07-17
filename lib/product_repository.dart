import 'dart:convert';
import 'package:flutter/services.dart';
import 'product.dart';

class ProductRepository {
  static Future<List<Product>> loadProducts() async {
    final String jsonString = await rootBundle.loadString('assets/products.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Product.fromJson(json)).toList();
  }
}
