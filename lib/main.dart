import 'package:flutter/material.dart';

import 'app/brain_buddies_app.dart';

Future<void> main() async {
  // Ensure bindings are ready before games touch SharedPreferences.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrainBuddiesApp());
}
