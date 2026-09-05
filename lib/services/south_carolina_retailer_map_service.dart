import 'package:flutter/foundation.dart';

class SouthCarolinaRetailerMapService {
  SouthCarolinaRetailerMapService._();

  static final ValueNotifier<bool> isVisible = ValueNotifier(false);

  static void show() => isVisible.value = true;

  static void hide() => isVisible.value = false;
}
