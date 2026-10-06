import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/responsive/design_size.dart';
import 'core/theme/game_colors.dart';
import 'features/game/presentation/game_page.dart';

class TetrisProApp extends StatelessWidget {
  const TetrisProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: designSizeFor(constraints.maxWidth),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => MaterialApp(
            title: 'Tetris Pro',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: GameColors.background,
            ),
            builder: (ctx, child) {
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
              );
              return child!;
            },
            home: const GamePage(),
          ),
        );
      },
    );
  }
}
