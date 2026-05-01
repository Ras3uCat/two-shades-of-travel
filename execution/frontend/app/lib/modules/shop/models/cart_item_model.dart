import 'product_model.dart';

class CartItemModel {
  CartItemModel({required this.product, this.quantity = 1});

  final ProductModel product;
  int quantity;

  int get subtotalCents => product.priceCents * quantity;
}
