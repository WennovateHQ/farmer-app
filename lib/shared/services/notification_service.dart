import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // Initialize settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings for all platforms
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'freshfarmily_farmer_notifications',
      'Farmer Notifications',
      channelDescription: 'Notifications for FreshFarmily Farmer App',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'app_icon',
      color: Colors.green,
    );

    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Method to notify about new orders
  Future<void> notifyNewOrder(Map<String, dynamic> order) async {
    await showNotification(
      id: order['id'] ?? 100,
      title: 'New Order Received',
      body: 'You have received a new order #${order['orderNumber']} for ${order['items_count']} items.',
      payload: 'order_${order['id']}',
    );
  }

  // Method to notify about order cancellations
  Future<void> notifyCancelledOrder(Map<String, dynamic> order) async {
    await showNotification(
      id: order['id'] ?? 200,
      title: 'Order Cancelled',
      body: 'Order #${order['orderNumber']} has been cancelled by the customer.',
      payload: 'order_${order['id']}',
    );
  }

  // Method to notify about low inventory
  Future<void> notifyLowInventory(String productName, int quantity) async {
    await showNotification(
      id: 300,
      title: 'Low Inventory Alert',
      body: 'Your product "$productName" is running low with only $quantity items left.',
      payload: 'inventory_$productName',
    );
  }

  // Method to notify about driver pickup
  Future<void> notifyDriverPickup(Map<String, dynamic> order, String driverName) async {
    await showNotification(
      id: order['id'] ?? 400,
      title: 'Order Pickup',
      body: 'Driver $driverName is picking up order #${order['orderNumber']}.',
      payload: 'pickup_${order['id']}',
    );
  }

  // Method to notify about successful delivery
  Future<void> notifyDeliveryComplete(Map<String, dynamic> order) async {
    await showNotification(
      id: order['id'] ?? 500,
      title: 'Delivery Complete',
      body: 'Order #${order['orderNumber']} has been successfully delivered to the customer.',
      payload: 'delivery_${order['id']}',
    );
  }

  // Check if user has notifications enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Simulate receiving a push notification for a new order
  Future<void> simulateNewOrderNotification() async {
    if (!await areNotificationsEnabled()) return;

    await showNotification(
      id: 999,
      title: 'New Order Received!',
      body: 'You have received a new order #5432 with 5 items totaling \$35.75.',
      payload: 'order_5432',
    );
  }
}
