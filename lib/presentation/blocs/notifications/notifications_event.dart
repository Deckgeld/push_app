part of 'notifications_bloc.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

// Este evento se dispara cuando el estado de las notificaciones cambia, cuando el usuario acepta o rechaza las notificaciones.
class NotificationStatusChanged extends NotificationsEvent {
  //el evento hace que el estado de las notificaciones cambie
  final AuthorizationStatus status;

  NotificationStatusChanged(this.status);
  
}

class NotificationReceived extends NotificationsEvent {
  final PushMessage message;

  NotificationReceived(this.message);
}