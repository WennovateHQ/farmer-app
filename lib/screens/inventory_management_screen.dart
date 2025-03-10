import 'package:flutter/material.dart';
import 'package:shared/models/product.dart';
import 'package:shared/services/inventory_service.dart';
import 'package:intl/intl.dart';
import 'package:shared/widgets/error_view.dart';
import 'package:shared/widgets/loading_indicator.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  // Filter options
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _stockFilter = false; // false: all products, true: low stock only

  // Create a List of available categories
  List<String> _categories = ['All'];

  // Selected products for bulk actions
  final Set<String> _selectedProductIds = {};
  bool _isSelectMode = false;

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

        // Apply stock filter
        final matchesStock =
            !_stockFilter || product.stock <= product.lowStockThreshold;

        return matchesSearch && matchesCategory && matchesStock;
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
      case 'stock':
        _filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'price':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'popularity':
        _filteredProducts.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
    }
  }

  Future<void> _updateProductStock(Product product, int newStock) async {
    try {
      await _inventoryService.updateProductStock(product.id, newStock);

      // Update local state
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product.copyWith(stock: newStock);
          _applyFilters();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated stock for ${product.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: $e')),
      );
    }
  }

  Future<void> _bulkUpdateStock(double percentage) async {
    // Show progress indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating inventory...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final selectedProducts =
          _products.where((p) => _selectedProductIds.contains(p.id)).toList();

      for (final product in selectedProducts) {
        final newStock = (product.stock * (1 + percentage / 100)).round();
        await _updateProductStock(product, newStock);
      }

      // Clear selection after bulk update
      setState(() {
        _selectedProductIds.clear();
        _isSelectMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${selectedProducts.length} products'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStockUpdateDialog(Product product) async {
    final TextEditingController controller = TextEditingController(
      text: product.stock.toString(),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Stock for ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Stock Level',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current stock: ${product.stock} units',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (product.stock <= product.lowStockThreshold)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Low Stock',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
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
                final newStock = int.tryParse(controller.text);
                if (newStock != null && newStock >= 0) {
                  Navigator.of(context).pop();
                  _updateProductStock(product, newStock);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid stock quantity'),
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

  Future<void> _showBulkUpdateDialog() async {
    double percentage = 0.0;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bulk Update Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selected ${_selectedProductIds.length} products'),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: percentage,
                        min: -50,
                        max: 100,
                        divisions: 30,
                        label: '${percentage.toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setState(() {
                            percentage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        percentage > 0
                            ? 'Increase stock by ${percentage.toStringAsFixed(0)}%'
                            : percentage < 0
                                ? 'Decrease stock by ${(-percentage).toStringAsFixed(0)}%'
                                : 'No change',
                        style: TextStyle(
                          color: percentage > 0
                              ? Colors.green
                              : percentage < 0
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
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
                Navigator.of(context).pop();
                _bulkUpdateStock(percentage);
              },
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    final isLowStock = product.stock <= product.lowStockThreshold;
    final isOutOfStock = product.stock == 0;

    Color stockColor = Colors.green;
    if (isOutOfStock) {
      stockColor = Colors.red;
    } else if (isLowStock) {
      stockColor = Colors.orange;
    }

    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (_isSelectMode)
              Checkbox(
                value: _selectedProductIds.contains(product.id),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedProductIds.add(product.id);
                    } else {
                      _selectedProductIds.remove(product.id);
                    }
                  });
                },
              ),
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
                  Row(
                    children: [
                      Text(
                        currencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: stockColor),
                        ),
                        child: Text(
                          isOutOfStock
                              ? 'Out of Stock'
                              : isLowStock
                                  ? 'Low: ${product.stock}'
                                  : 'In Stock: ${product.stock}',
                          style: TextStyle(
                            color: stockColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (!_isSelectMode)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showStockUpdateDialog(product),
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
        title: !_isSelectMode
            ? const Text('Inventory Management')
            : Text('${_selectedProductIds.length} Selected'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectMode = false;
                  _selectedProductIds.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _isSelectMode = true;
                });
              },
            ),
          if (_isSelectMode && _selectedProductIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showBulkUpdateDialog,
            ),
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
                                          value: 'stock',
                                          child: Text('Sort by: Stock'),
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
                                    const SizedBox(width: 16),
                                    // Low stock filter
                                    FilterChip(
                                      label: const Text('Low Stock'),
                                      selected: _stockFilter,
                                      onSelected: (selected) {
                                        setState(() {
                                          _stockFilter = selected;
                                          _applyFilters();
                                        });
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
                                            _selectedCategory != 'All' ||
                                            _stockFilter
                                        ? 'No products match your filters'
                                        : 'No products in inventory',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (_searchQuery.isNotEmpty ||
                                      _selectedCategory != 'All' ||
                                      _stockFilter)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedCategory = 'All';
                                          _stockFilter = false;
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
      floatingActionButton: !_isSelectMode && !_isLoading
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to add product screen (to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Add Product functionality coming soon')),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
