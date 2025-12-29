import 'package:node_deployement/services/config_service_io.dart'
    if (dart.library.html) 'package:node_deployement/services/config_service_web.dart';

Future<String> loadNodesConfig() => loadNodesConfigImpl();
