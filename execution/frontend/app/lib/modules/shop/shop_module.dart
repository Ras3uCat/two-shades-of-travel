import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'bindings/shop_binding.dart';
import 'views/shop_view.dart';
import 'views/product_detail_view.dart';
import 'views/cart_view.dart';
import 'views/order_confirmation_view.dart';

class ShopModule implements AppModule {
  @override
  String get moduleId => 'shop';

  @override
  NavItem? get navItem => NavItem(
        label: 'Shop',
        icon: Icons.store_outlined,
        route: ERoutes.shop,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.shop,
          page: () => const ShopView(),
          binding: ShopBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.shopProduct,
          page: () => const ProductDetailView(),
          binding: ShopBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.shopCart,
          page: () => const CartView(),
          binding: ShopBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.shopConfirmation,
          page: () => const OrderConfirmationView(),
          binding: ShopBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
