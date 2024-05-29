import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(const NotificationsState()) {

    // Escuchamos los eventos de cambio de estado de las notificaciones
    on<NotificationStatusChanged>(_notificationStatusChanged);
  }

  //metodo que inicializa las notificaciones de firebase
  static Future<void> initializeFirebaseNotifications() async{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } 

  //metodo que usa el evento que creamos antes dentro de notifications_event.dart
  void _notificationStatusChanged(NotificationStatusChanged event, Emitter<NotificationsState> emit) {
    emit(
      state.copyWith(
        status: event.status
      )
    );
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
