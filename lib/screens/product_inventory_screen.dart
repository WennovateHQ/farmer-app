import 'package:flutter/material.dart';
import 'package:shared/services/api_service.dart';
import 'product_detail_screen.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});

  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _filterCategory = 'All';
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Meat',
    'Poultry',
    'Grains',
    'Herbs',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, we would use the API service to get products
      // For demo purposes, we'll create mock data
      await Future.delayed(const Duration(seconds: 1));

      _products = [
        {
          'id': 1,
          'name': 'Organic Tomatoes',
          'description': 'Freshly grown organic tomatoes.',
          'price': 3.99,
          'inventory': 50,
          'category': 'Vegetables',
          'isOrganic': true,
          'isAvailable': true,
          'imageUrl': 'https://example.com/images/tomatoes.jpg',
        },
        {
          'id': 2,
          'name': 'Fresh Strawberries',
          'description': 'Sweet and juicy strawberries picked daily.',
          'price': 4.99,
          'inventory': 30,
          'category': 'Fruits',
          'isOrganic': true,
          'isAvailable': true,
          'imageUrl': 'https://example.com/images/strawberries.jpg',
        },
        {
          'id': 3,
          'name': 'Whole Milk',
          'description': 'Farm fresh whole milk.',
          'price': 2.99,
          'inventory': 20,
          'category': 'Dairy',
          'isOrganic': false,
          'isAvailable': true,
          'imageUrl': 'https://example.com/images/milk.jpg',
        },
        {
          'id': 4,
          'name': 'Free-range Eggs',
          'description': 'Eggs from free-range chickens.',
          'price': 3.49,
          'inventory': 40,
          'category': 'Poultry',
          'isOrganic': true,
          'isAvailable': true,
          'imageUrl': 'https://example.com/images/eggs.jpg',
        },
        {
          'id': 5,
          'name': 'Organic Carrots',
          'description': 'Organically grown carrots.',
          'price': 2.49,
          'inventory': 60,
          'category': 'Vegetables',
          'isOrganic': true,
          'isAvailable': true,
          'imageUrl': 'https://example.com/images/carrots.jpg',
        },
      ];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_filterCategory == 'All') {
      return _products;
    }
    return _products
        .where((product) => product['category'] == _filterCategory)
        .toList();
  }

  Future<void> _navigateToProductDetail(Map<String, dynamic>? product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product,
          isEditing: product != null,
        ),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality would go here
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _filterCategory == 'All'
                            ? 'No products available'
                            : 'No $_filterCategory products found',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToProductDetail(null),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductDetail(null),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final inventory = product['inventory'] as int;
    final bool isLowInventory = inventory < 10;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: product['imageUrl'] != null
                      ? DecorationImage(
                          image: NetworkImage(product['imageUrl']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product['imageUrl'] == null
                    ? const Icon(Icons.image, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (product['isOrganic'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Organic',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (!product['isAvailable'])
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Not Available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 16,
                              color: isLowInventory
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: ${product['inventory']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isLowInventory
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontWeight: isLowInventory
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: _filterCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _filterCategory = category;
                            });
                            this.setState(() {});
                          }
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _filterCategory == category
                              ? Colors.white
                              : Colors.black,
                          fontWeight: _filterCategory == category
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Apply Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
