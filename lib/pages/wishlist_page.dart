import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import '../widgets/car_dealer/dealer_wishlist.dart';

@RoutePage()
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) => const DealerWishlist();
}
