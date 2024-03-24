import 'package:flutter/foundation.dart';

const debugHostOrigin = kDebugMode
    ? String.fromEnvironment("DEBUG_HOST_ORIGIN",
        defaultValue: "http://127.0.0.1:18960")
    : "";
