import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

import 'views/home_view.dart';
import 'views/mock_exam_view.dart';
import 'views/record_view.dart';
import 'views/settings_view.dart';
import 'views/study_view.dart';

class Otsu4App extends StatelessWidget {
  const Otsu4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'うかラボ 危険物乙4',
      debugShowCheckedModeBanner: false,
      theme: UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      darkTheme: UkalabTheme.dark(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      home: const UkalabShell(
        pages: [
          HomeView(),
          StudyView(),
          MockExamView(),
          RecordView(),
          SettingsView(),
        ],
      ),
    );
  }
}
