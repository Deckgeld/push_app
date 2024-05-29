import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}


class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(const NotificationsState()) {
    // Escuchamos los eventos de cambio de estado de las notificaciones
    on<NotificationStatusChanged>(_notificationStatusChanged);

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

  void _handleRemoteMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('message: ${message.data}');

    if (message.notification == null) return; 
    
    print('Message also contained a notification: ${message.notification}');
    
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
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
}
