import 'package:flutter/material.dart';

import 'app.dart';
import 'core/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressStore.instance.load();
  runApp(const DatabaseArchitectLabApp());
}
