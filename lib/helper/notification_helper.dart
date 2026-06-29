import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    await flutterLocalNotificationsPlugin.initialize(initializationsSettings,
        onDidReceiveNotificationResponse: (load) async {
      try {
        if (load.payload!.isNotEmpty) {
          NotificationBodyModel payload =
              NotificationBodyModel.fromJson(jsonDecode(load.payload!));

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
                RouteHelper.getOrderDetailsRoute(payload.orderId,
                    fromNotification: true)),
            NotificationType.order_request: () =>
                Get.toNamed(RouteHelper.getMainRoute('order-request')),
            NotificationType.block: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.unblock: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.otp: () => null,
            NotificationType.unassign: () =>
                Get.to(const DashboardScreen(pageIndex: 1)),
            NotificationType.message: () => Get.toNamed(
                RouteHelper.getChatRoute(
                    notificationBody: payload,
                    conversationId: payload.conversationId,
                    fromNotification: true)),
            NotificationType.general: () => Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true)),
          };

          notificationActions[payload.notificationType]?.call();
        }
      } catch (_) {}
      return;
    });
    if (GetPlatform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidNotifications =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          '6ammart',
          'The Delivery alerts',
          description: 'Order, chat, and general driver alerts',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );
      await androidNotifications?.requestNotificationsPermission();
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("onMessage message type:${message.data['type']}");
        print("onMessage message:${message.data}");
      }

      if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.chatScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
          if (Get.find<ChatController>()
                  .messageModel!
                  .conversation!
                  .id
                  .toString() ==
              message.data['conversation_id'].toString()) {
            Get.find<ChatController>().getMessages(
              1,
              NotificationBodyModel(
                notificationType: NotificationType.message,
                customerId:
                    message.data['sender_type'] == AppConstants.user ? 0 : null,
                vendorId: message.data['sender_type'] == AppConstants.vendor
                    ? 0
                    : null,
              ),
              null,
              int.parse(message.data['conversation_id'].toString()),
            );
          } else {
            NotificationHelper.showNotification(
                message, flutterLocalNotificationsPlugin);
          }
        }
      } else if (message.data['type'] == 'message' &&
          Get.currentRoute.startsWith(RouteHelper.conversationListScreen)) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<ChatController>().getConversationList(1);
        }
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
      } else if (message.data['type'] == 'otp') {
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
      } else {
        String? type = message.data['type'];

        if (type != 'assign' &&
            type != 'new_order' &&
            type != 'order_request') {
          NotificationHelper.showNotification(
              message, flutterLocalNotificationsPlugin);
          Get.find<OrderController>().getCurrentOrders();
          Get.find<OrderController>().getLatestOrders();
          Get.find<NotificationController>().getNotificationList();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("onOpenApp message type:${message.data['type']}");
      }
      try {
        if (message.data.isNotEmpty) {
          NotificationBodyModel notificationBody =
              convertNotification(message.data)!;

          final Map<NotificationType, Function> notificationActions = {
            NotificationType.order: () => Get.toNamed(
                RouteHelper.getOrderDetailsRoute(
                    int.parse(message.data['order_id']),
                    fromNotification: true)),
            NotificationType.order_request: () =>
                Get.toNamed(RouteHelper.getMainRoute('order-request')),
            NotificationType.block: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.unblock: () =>
                Get.offAllNamed(RouteHelper.getSignInRoute()),
            NotificationType.otp: () => null,
            NotificationType.unassign: () =>
                Get.to(const DashboardScreen(pageIndex: 1)),
            NotificationType.message: () => Get.toNamed(
                RouteHelper.getChatRoute(
                    notificationBody: notificationBody,
                    conversationId: notificationBody.conversationId,
                    fromNotification: true)),
            NotificationType.general: () => Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true)),
          };

          notificationActions[notificationBody.notificationType]?.call();
        }
      } catch (_) {}
    });
  }

  static Future<void> showNotification(
      RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if (!GetPlatform.isIOS) {
      String? title;
      String? body;
      String? image;
      NotificationBodyModel? notificationBody =
          convertNotification(message.data);

      title = message.data['title'] ?? message.notification?.title;
      body = message.data['body'] ??
          message.data['description'] ??
          message.notification?.body;
      String? rawImage = message.data['image']?.toString();
      image = (rawImage != null && rawImage.isNotEmpty)
          ? rawImage.startsWith('http')
              ? rawImage
              : '${AppConstants.baseUrl}/storage/app/public/notification/$rawImage'
          : null;

      if (body == null || body.trim().isEmpty) {
        return;
      }
      title = (title == null || title.trim().isEmpty)
          ? AppConstants.appName
          : title;

      if (image != null && image.isNotEmpty) {
        try {
          await showBigPictureNotificationHiddenLargeIcon(
              title, body, notificationBody, image, fln);
        } catch (e) {
          await showBigTextNotification(title, body, notificationBody, fln);
        }
      } else {
        await showBigTextNotification(title, body, notificationBody, fln);
      }
    }
  }

  static Future<void> showTextNotification(
      String title,
      String body,
      NotificationBodyModel notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      playSound: true,
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: jsonEncode(notificationBody.toJson()));
  }

  static Future<void> showBigTextNotification(
      String? title,
      String body,
      NotificationBodyModel? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String? title,
      String? body,
      NotificationBodyModel? notificationBody,
      String image,
      FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath =
        await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6ammart',
      '6ammart',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      priority: Priority.max,
      playSound: true,
      styleInformation: bigPictureStyleInformation,
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<String> _downloadAndSaveFile(
      String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBodyModel? convertNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final orderId = data['order_id'];

    switch (type) {
      case 'cash_collect':
        return NotificationBodyModel(
            notificationType: NotificationType.general);
      case 'unassign':
        return NotificationBodyModel(
            notificationType: NotificationType.unassign);
      case 'order_status':
        return NotificationBodyModel(
            orderId: int.parse(orderId),
            notificationType: NotificationType.order);
      case 'order_request':
        return NotificationBodyModel(
            orderId: int.parse(orderId),
            notificationType: NotificationType.order_request);
      case 'block':
        return NotificationBodyModel(notificationType: NotificationType.block);
      case 'unblock':
        return NotificationBodyModel(
            notificationType: NotificationType.unblock);
      case 'otp':
        return NotificationBodyModel(notificationType: NotificationType.otp);
      case 'message':
        return _handleMessageNotification(data);
      default:
        return NotificationBodyModel(
            notificationType: NotificationType.general);
    }
  }

  static NotificationBodyModel _handleMessageNotification(
      Map<String, dynamic> data) {
    final conversationId = data['conversation_id'];
    final senderType = data['sender_type'];

    return NotificationBodyModel(
      conversationId: (conversationId != null && conversationId.isNotEmpty)
          ? int.parse(conversationId)
          : null,
      notificationType: NotificationType.message,
      type: senderType == AppConstants.user
          ? AppConstants.user
          : AppConstants.vendor,
    );
  }
}

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("onBackground: ${message.data}");
  }
}
