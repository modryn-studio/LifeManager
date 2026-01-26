import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling local notifications
/// 
/// MVP uses local notifications + polling instead of FCM push
/// App must be opened to receive notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  /// Initialize the notification service
  /// 
  /// Sets up Android notification channel with high importance
  /// Must be called before showing any notifications
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android 8.0+
    await _createNotificationChannel();
    
    _initialized = true;
  }
  
  /// Create the notification channel
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'lifemanager_channel',
      'LifeManager Notifications',
      description: 'Notifications for task reminders and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to relevant screen based on payload
    // For MVP, just opening the app is sufficient
  }

  /// Show a local notification
  /// 
  /// [title] - Notification title (e.g., "Morning ❤️")
  /// [body] - Notification body text
  /// [payload] - Optional data to pass when notification is tapped
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    const androidDetails = AndroidNotificationDetails(
      'lifemanager_channel',
      'LifeManager Notifications',
      channelDescription: 'Notifications for task reminders and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // Use current timestamp as notification ID for uniqueness
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  /// Show a task completion toast notification
  /// 
  /// Used when partner completes a task
  static Future<void> showPartnerCompletedTask({
    required String partnerName,
    required String taskTitle,
  }) async {
    await showNotification(
      title: 'Task Completed ✓',
      body: '$partnerName completed: $taskTitle',
    );
  }
  
  /// Show a morning digest notification
  static Future<void> showMorningDigest({
    required String message,
  }) async {
    await showNotification(
      title: 'Morning ❤️',
      body: message,
    );
  }
  
  /// Show a follow-up reminder
  static Future<void> showFollowUpReminder({
    required String message,
  }) async {
    await showNotification(
      title: 'Quick Check-in 😊',
      body: message,
    );
  }
  
  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return true;
  }
  
  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true;
  }
  
  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
