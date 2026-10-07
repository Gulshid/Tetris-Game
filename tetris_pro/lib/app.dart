import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/responsive/design_size.dart';
import 'core/theme/game_colors.dart';
import 'features/game/presentation/game_page.dart';

class TetrisProApp extends StatelessWidget {
  const TetrisProApp({super.key});

  static ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GameColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GameColors.accent,
      secondary: GameColors.accentAlt,
      surface: GameColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: GameColors.background,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: GameColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.border),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

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
            theme: _theme(),
            builder: (ctx, child) {
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: GameColors.backgroundDeep,
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
