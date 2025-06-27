import 'package:permission_handler/permission_handler.dart';

Future<bool> requestAudioPermission() async {
  // On Android 13+, use audio permission
  final permission = Permission.audio;
  if (await permission.isGranted) return true;

  final result = await permission.request();
  return result.isGranted;
}
