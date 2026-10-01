import '/config.dart';
import '/gvam_content_sync/device_usage_service.dart';

export '/resources/services/mastersync/mastersync.dart';

part '/resources/services/alert_modal_service.dart';
part '/resources/services/app_service.dart';
part '/resources/services/ble_alert_service.dart';
part '/resources/services/map_service.dart';
part '/resources/services/navigation_service.dart';
part '/resources/services/text_size_service.dart';

final ApplicationService services = Get.find();
final navigatorKey = GlobalKey<NavigatorState>();
