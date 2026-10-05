import 'dart:ui' show Size;

/// Responsive design size, same breakpoint pattern as the other app.
///
/// Used by ScreenUtilInit for HUD, panels, buttons and text (.w .h .sp .r).
/// The game BOARD does not use ScreenUtil: it is sized with LayoutBuilder
/// (cell size = available width / 10) so it always keeps a 1:2 ratio.
Size designSizeFor(double width) {
  if (width < 600) return const Size(360, 800); // phone
  if (width < 1200) return const Size(834, 1194); // tablet
  return const Size(1440, 1024); // desktop
}
