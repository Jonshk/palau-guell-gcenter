part of '../config/services.dart';

class AlertModalService extends GetxService {
  bool hasOpened = false;
  bool surveySend = false;

  void checkAlert() {
    if (Get.context != null) {
      action(CustomerPlaceAlert alert) {
        if (!hasOpened && !surveySend) {
          hasOpened = true;
          showDialog(context: Get.context!, builder: (context) => AlertModal());
        }
      }

      services.alerts.checkAlertTriggers(
        AlertTriggerType.clientAlertContentAccess,
        action,
        services.contents.current.uuid,
      );
    }
  }
}
