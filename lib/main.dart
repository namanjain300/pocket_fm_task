import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'product_repository.dart';
import 'product.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => CartProvider()..loadCart(), child: MaterialApp(title: 'Shopsy', theme: ThemeData(primarySwatch: Colors.blue), home: const ProductListScreen()));
  }
}

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                    },
                  ),
                  if (cart.items.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text('${cart.items.length}', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: ProductRepository.loadProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CachedNetworkImage(imageUrl: product.image, width: 56, height: 56, fit: BoxFit.cover, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error)),
                title: Text(product.name),
                subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: CachedNetworkImage(imageUrl: widget.product.image, height: 180, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error))),
            const SizedBox(height: 16),
            Text(widget.product.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('₹${widget.product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.star, color: Colors.amber, size: 20), Text(widget.product.rating.toString())]),
            const SizedBox(height: 16),
            Text(widget.product.description),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => quantity++);
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    cart.addToCart(widget.product, quantity: quantity);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body:
          cart.items.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return ListTile(
                          leading: CachedNetworkImage(imageUrl: item.product.image, width: 48, height: 48, fit: BoxFit.cover, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error)),
                          title: Text(item.product.name),
                          subtitle: Text('₹${item.product.price.toStringAsFixed(2)} x ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    cart.updateQuantity(item.product, item.quantity - 1);
                                  }
                                },
                              ),
                              Text(item.quantity.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  cart.updateQuantity(item.product, item.quantity + 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  cart.removeFromCart(item.product);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('₹${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
    );
  }
}
