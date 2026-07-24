import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cams_urls.dart';

const String androidWidgetProviderName = 'ToprCamWidgetProvider';
const String widgetCamPrefsKey = 'widgetSelectedCam';
const String widgetScanModePrefsKey = 'widgetScanMode';
const String defaultWidgetCam = 'Morskie Oko: Rysy';
const String scanCamValue = '__scan__';

class ToprWidgetService {
  static Future<String> getSelectedCam() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(widgetCamPrefsKey);
    if (saved != null && imagesUrls.containsKey(saved)) return saved;
    return defaultWidgetCam;
  }

  static Future<bool> isScanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(widgetScanModePrefsKey) ?? false;
  }

  static Future<void> setSelectedCam(String camName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widgetCamPrefsKey, camName);
    await prefs.setBool(widgetScanModePrefsKey, false);
    await _pushToWidget(camName);
  }

  static Future<void> setScanMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widgetScanModePrefsKey, true);
    await _pushScanData();
  }

  static Future<void> syncWidget() async {
    if (await isScanMode()) {
      await _pushScanData();
    } else {
      final camName = await getSelectedCam();
      await _pushToWidget(camName);
    }
  }

  static Future<void> _pushToWidget(String camName) async {
    final url = imagesUrls[camName];
    if (url == null) return;
    final code = camCodeFromUrl(url);
    await HomeWidget.saveWidgetData<String>('cam_code', code);
    await HomeWidget.saveWidgetData<String>('cam_name', camName);
    await HomeWidget.saveWidgetData<bool>('scan_mode', false);
    await HomeWidget.updateWidget(androidName: androidWidgetProviderName);
  }

  static Future<void> _pushScanData() async {
    final names = imagesUrls.keys.toList();
    final codes = names.map((n) => camCodeFromUrl(imagesUrls[n]!)).toList();
    await HomeWidget.saveWidgetData<String>('scan_cam_names', names.join('|'));
    await HomeWidget.saveWidgetData<String>('scan_cam_codes', codes.join('|'));
    await HomeWidget.saveWidgetData<bool>('scan_mode', true);
    await HomeWidget.updateWidget(androidName: androidWidgetProviderName);
  }

  static Future<void> requestPinWidget() {
    return HomeWidget.requestPinWidget(
      androidName: androidWidgetProviderName,
    );
  }
}
