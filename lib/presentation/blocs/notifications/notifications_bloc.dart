import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/domain/entitites/push_message.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  //Todo: Implemetar una BD local para guardar las notificaciones
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(const NotificationsState()) {
    // Escuchamos los eventos de cambio de estado de las notificaciones
    on<NotificationStatusChanged>(_notificationStatusChanged);
    on<NotificationReceived>(_notificationReceived);


    // Vertificamos el estado actual de las notificaciones
    _initialStatusCheck();

    // Listeners para los mensajes en Foreground
    _onForegroundMessage();
  }

  //metodo que inicializa las notificaciones de firebase
  static Future<void> initializeFirebaseNotifications() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //metodo que usa el evento que creamos antes dentro de notifications_event.dart
  void _notificationStatusChanged(
      NotificationStatusChanged event, Emitter<NotificationsState> emit) {
    emit(
      state.copyWith(status: event.status),
    );
    _getFCMToken();
  }

  void _notificationReceived(
      NotificationReceived event, Emitter<NotificationsState> emit) {
    emit(
      state.copyWith(
        notifications: [ event.message, ...state.notifications],
      ),
    );
  }

  //metodo que se encarga de verificar el estado actual de las notificaciones, es llamado en el constructor
  void _initialStatusCheck() async {
    final settings = await messaging.getNotificationSettings();
    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  //Firebase Cloud Messaging Token
  void _getFCMToken() async {
    if (state.status == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print('Token: $token');
    }
  }

  void handleRemoteMessage(RemoteMessage message) {
    if (message.notification == null) return;

    final notification = PushMessage(
      messageId: message.messageId
        //Si messageId difetente a null, reemplazamos los caracteres : y % por un string vacio
        ?.replaceAll(':', '').replaceAll('%', '')
        //Si messageId es null, retornamos un string vacio
        ?? '',
      title: message.notification!.title ?? '', 
      body: message.notification!.body ?? '', 
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      //platform se importa de dart:io
      imageUrl: Platform.isAndroid
          ? message.notification!.android?.imageUrl
          : message.notification!.apple?.imageUrl,
    );
    
    add(NotificationReceived(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  //Este metodo es llamado desde la UI al precionar un boton
  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Disparamos el evento de cambio de estado de las notificaciones
    add(NotificationStatusChanged(settings.authorizationStatus));
  }

  //Metodo para obtener un mensaje por su id
  PushMessage? getMesssageById(String messageId) {
    final exist = state.notifications.any(
      (element) => element.messageId == messageId,
    );
    
    if ( !exist ) return null;
    return state.notifications.firstWhere(
      (element) => element.messageId == messageId,
    );
  }
}
