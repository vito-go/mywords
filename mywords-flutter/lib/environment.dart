import 'package:flutter/foundation.dart';

// debug defaultValue http://127.0.0.1:18960
// should be empty when in product environment
const debugHostOrigin = kDebugMode
    ? String.fromEnvironment("DEBUG_HOST_ORIGIN",
        defaultValue: "http://127.0.0.1:18960")
    : "";
// web版本页面body宽度，<=0意味不设置
const webBodyWidth = int.fromEnvironment("WEB_BODY_WIDTH", defaultValue: 1080);
