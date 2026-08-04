#include "my_application.h"

int main(int argc, char** argv) {
  // Force GTK & Graphics driver to high refresh rate (240Hz) and bypass 60 FPS caps
  g_setenv("GDK_BACKEND", "wayland,x11", FALSE);
  g_setenv("CLUTTER_DEFAULT_FPS", "240", FALSE);
  g_setenv("GDK_FRAME_CLOCK_NO_VSYNC", "1", FALSE);
  g_setenv("vblank_mode", "0", FALSE);
  g_setenv("__GL_SYNC_TO_VBLANK", "0", FALSE);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
