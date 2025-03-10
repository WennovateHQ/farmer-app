import 'package:flutter/material.dart';
import 'package:shared/models/product.dart';
import 'package:shared/services/inventory_service.dart';
import 'package:shared/widgets/error_view.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  State<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  // Filter options
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  // Create a List of available categories
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _inventoryService.getInventory();

      // Extract unique categories
      final categories =
          products.map((product) => product.category).toSet().toList();
      categories.sort();

      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
        _categories = ['All', ...categories];
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Apply search filter
        final matchesSearch =
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                product.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

        // Apply category filter
        final matchesCategory =
            _selectedCategory == 'All' || product.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Apply sorting
      _sortProducts();
    });
  }

  void _sortProducts() {
    switch (_sortBy) {
      case 'name':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'popularity':
        _filteredProducts.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
    }
  }

  Future<void> _updateProductPrice(Product product, double newPrice) async {
    try {
      await _inventoryService.updateProductPrice(product.id, newPrice);

      // Update local state
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product.copyWith(price: newPrice);
          _applyFilters();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated price for ${product.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update price: $e')),
      );
    }
  }

  Future<void> _showPriceUpdateDialog(Product product) async {
    final TextEditingController controller = TextEditingController(
      text: product.price.toString(),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Price for ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Price',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current price: \$${product.price.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final newPrice = double.tryParse(controller.text);
                if (newPrice != null && newPrice >= 0) {
                  Navigator.of(context).pop();
                  _updateProductPrice(product, newPrice);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price'),
                    ),
                  );
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Product image or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(Icons.inventory_2, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showPriceUpdateDialog(product),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorView(
                  message: _errorMessage!,
                  onRetry: _loadInventory,
                )
              : Column(
                  children: [
                    // Search and filter section
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search products',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Category filter
                                    DropdownButton<String>(
                                      value: _selectedCategory,
                                      items: _categories.map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedCategory = value;
                                            _applyFilters();
                                          });
                                        }
                                      },
                                      hint: const Text('Category'),
                                    ),
                                    const SizedBox(width: 16),
                                    // Sort options
                                    DropdownButton<String>(
                                      value: _sortBy,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'name',
                                          child: Text('Sort by: Name'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'price',
                                          child: Text('Sort by: Price'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'popularity',
                                          child: Text('Sort by: Popularity'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _sortBy = value;
                                            _applyFilters();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // List of products
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedCategory != 'All'
                                        ? 'No products match your filters'
                                        : 'No products in inventory',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _selectedCategory != 'All')
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedCategory = 'All';
                                          _applyFilters();
                                        });
                                      },
                                      child: const Text('Clear Filters'),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                return _buildProductItem(
                                    _filteredProducts[index]);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
