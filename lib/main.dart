import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:resq_admin/Admin/dashboard.dart';
import 'firebase_options.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ResQAdminApp());
}

class ResQAdminApp extends StatelessWidget {
  const ResQAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ Admin Panel',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),

      home: const AdminDashboard(),
    );
  }
}