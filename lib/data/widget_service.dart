import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cams_urls.dart';

const String androidWidgetProviderName = 'ToprCamWidgetProvider';
const String widgetCamPrefsKey = 'widgetSelectedCam';
const String defaultWidgetCam = 'Morskie Oko: Rysy';

class ToprWidgetService {
  static Future<String> getSelectedCam() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(widgetCamPrefsKey);
    if (saved != null && imagesUrls.containsKey(saved)) return saved;
    return defaultWidgetCam;
  }

  static Future<void> setSelectedCam(String camName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widgetCamPrefsKey, camName);
    await _pushToWidget(camName);
  }

  static Future<void> syncWidget() async {
    final camName = await getSelectedCam();
    await _pushToWidget(camName);
  }

  static Future<void> _pushToWidget(String camName) async {
    final url = imagesUrls[camName];
    if (url == null) return;
    final code = camCodeFromUrl(url);
    await HomeWidget.saveWidgetData<String>('cam_code', code);
    await HomeWidget.saveWidgetData<String>('cam_name', camName);
    await HomeWidget.updateWidget(androidName: androidWidgetProviderName);
  }

  static Future<void> requestPinWidget() {
    return HomeWidget.requestPinWidget(
      androidName: androidWidgetProviderName,
    );
  }
}
