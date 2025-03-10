import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/models/analytics_data.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Analytics data
  SalesAnalytics? _salesData;
  CustomerAnalytics? _customerData;
  ProductAnalytics? _productData;

  // Time range
  String _selectedTimeRange = 'week';
  final Map<String, String> _timeRanges = {
    'day': 'Today',
    'week': 'This Week',
    'month': 'This Month',
    'year': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final salesData = await _analyticsService.getSalesAnalytics(
          timeRange: _selectedTimeRange);
      final customerData = await _analyticsService.getCustomerAnalytics(
          timeRange: _selectedTimeRange);
      final productData = await _analyticsService.getProductAnalytics(
          timeRange: _selectedTimeRange);

      setState(() {
        _salesData = salesData;
        _customerData = customerData;
        _productData = productData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildSalesTab() {
    if (_salesData == null) {
      return const Center(
        child: Text('No sales data available for the selected period'),
      );
    }

    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                'Total Revenue',
                currencyFormatter.format(_salesData!.totalRevenue),
                Icons.attach_money,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Orders',
                _salesData!.totalOrders.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                'Average Order',
                currencyFormatter.format(_salesData!.averageOrderValue),
                Icons.trending_up,
                Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Conversion Rate',
                '${(_salesData!.conversionRate * 100).toStringAsFixed(1)}%',
                Icons.swap_horiz,
                Colors.purple,
              ),
            ],
          ),

          // Revenue chart
          const SizedBox(height: 32),
          const Text(
            'Revenue Over Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >=
                                _salesData!.revenueOverTime.length ||
                            value.toInt() < 0) {
                          return const Text('');
                        }
                        return Text(
                          _getTimeLabel(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          currencyFormatter.format(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _salesData!.revenueOverTime
                        .asMap()
                        .entries
                        .map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top products table
          const SizedBox(height: 32),
          const Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Units')),
                DataColumn(label: Text('Revenue')),
              ],
              rows: _salesData!.topProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(Text(product.name)),
                    DataCell(Text(product.unitsSold.toString())),
                    DataCell(Text(currencyFormatter.format(product.revenue))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTab() {
    if (_customerData == null) {
      return const Center(
        child: Text('No customer data available for the selected period'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                'Total Customers',
                _customerData!.totalCustomers.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'New Customers',
                _customerData!.newCustomers.toString(),
                Icons.person_add,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                'Returning Rate',
                '${(_customerData!.returningRate * 100).toStringAsFixed(1)}%',
                Icons.replay,
                Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Avg. Satisfaction',
                '${_customerData!.averageSatisfaction.toStringAsFixed(1)}/5',
                Icons.sentiment_satisfied,
                Colors.purple,
              ),
            ],
          ),

          // Customer demographics
          const SizedBox(height: 32),
          const Text(
            'Customer Demographics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections:
                    _customerData!.demographics.asMap().entries.map((entry) {
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.amber,
                    Colors.red,
                    Colors.purple,
                    Colors.teal
                  ];
                  return PieChartSectionData(
                    color: colors[entry.key % colors.length],
                    value: entry.value.percentage,
                    title:
                        '${entry.value.group}\n${entry.value.percentage.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),

          // Customer locations
          const SizedBox(height: 32),
          const Text(
            'Top Customer Locations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Customers')),
                DataColumn(label: Text('% of Total')),
              ],
              rows: _customerData!.topLocations.map((location) {
                return DataRow(
                  cells: [
                    DataCell(Text(location.name)),
                    DataCell(Text(location.customers.toString())),
                    DataCell(
                        Text('${location.percentage.toStringAsFixed(1)}%')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTab() {
    if (_productData == null) {
      return const Center(
        child: Text('No product data available for the selected period'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                'Total Products',
                _productData!.totalProducts.toString(),
                Icons.inventory_2,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Avg. Rating',
                '${_productData!.averageRating.toStringAsFixed(1)}/5',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryCard(
                'Stock-outs',
                _productData!.stockOuts.toString(),
                Icons.report_problem,
                Colors.red,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Low Stock',
                _productData!.lowStock.toString(),
                Icons.warning,
                Colors.orange,
              ),
            ],
          ),

          // Product performance chart
          const SizedBox(height: 32),
          const Text(
            'Top Product Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _productData!.productPerformance.fold(
                        0,
                        (max, item) =>
                            item.performance > max ? item.performance : max) *
                    1.2,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >=
                                _productData!.productPerformance.length ||
                            value.toInt() < 0) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _productData!
                                .productPerformance[value.toInt()].name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: _productData!.productPerformance
                    .asMap()
                    .entries
                    .map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.performance,
                        color: Colors.blue,
                        width: 22,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _productData!.productPerformance.fold(
                                  0,
                                  (max, item) => item.performance > max
                                      ? item.performance
                                      : max) *
                              1.2,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Product inventory status
          const SizedBox(height: 32),
          const Text(
            'Inventory Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('In Stock')),
                DataColumn(label: Text('Status')),
              ],
              rows: _productData!.inventoryStatus.map((product) {
                Color statusColor;
                IconData statusIcon;

                if (product.stockLevel == 0) {
                  statusColor = Colors.red;
                  statusIcon = Icons.error;
                } else if (product.stockLevel < 10) {
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning;
                } else {
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(product.name)),
                    DataCell(Text(product.stockLevel.toString())),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          product.stockLevel == 0
                              ? 'Out of Stock'
                              : product.stockLevel < 10
                                  ? 'Low Stock'
                                  : 'In Stock',
                          style: TextStyle(color: statusColor),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeLabel(int index) {
    switch (_selectedTimeRange) {
      case 'day':
        return '${index * 2}h';
      case 'week':
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[index % 7];
      case 'month':
        return '${index + 1}';
      case 'year':
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return months[index % 12];
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sales', icon: Icon(Icons.attach_money)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
            Tab(text: 'Products', icon: Icon(Icons.inventory_2)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadAnalyticsData();
            },
            itemBuilder: (context) => _timeRanges.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesTab(),
                    _buildCustomerTab(),
                    _buildProductTab(),
                  ],
                ),
    );
  }
}
