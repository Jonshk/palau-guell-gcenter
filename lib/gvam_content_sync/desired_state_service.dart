import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_identity_service.dart';

class DesiredStatePlan {
  final String? action;
  final String compliance;
  final bool allowedFromDevice;
  final bool conditionsOk;
  final List<String> conditionReasons;
  const DesiredStatePlan({required this.action,required this.compliance,required this.allowedFromDevice,required this.conditionsOk,required this.conditionReasons});
  bool get isConformant => action == null;
}

class DesiredStateService {
  static const String baseUrl='http://192.168.1.96:8080';
  final DeviceIdentityService _identity=DeviceIdentityService();

  Future<DesiredStatePlan> getPlan() async {
    final id=await _identity.getOrCreateDeviceId();
    final r=await http.get(Uri.parse('$baseUrl/api/device/$id/desired-plan')).timeout(const Duration(seconds:10));
    if(r.statusCode!=200) throw Exception('No se pudo consultar el estado deseado. HTTP ${r.statusCode}');
    final d=jsonDecode(r.body) as Map<String,dynamic>;
    return DesiredStatePlan(
      action:d['action']?.toString(),
      compliance:d['compliance']?.toString()??'unknown',
      allowedFromDevice:d['allowed_from_device']==true,
      conditionsOk:d['conditions_ok']==true,
      conditionReasons:(d['condition_reasons'] as List? ?? const []).map((e)=>e.toString()).toList(),
    );
  }
}
