enum TimerMode {
  start,
  stop,
  reset,
}

enum DisplayMode {
  on,
  off,
}

enum PowerMode {
  on,
  off,
  sleep,
}

abstract class AbstractScale {
  Future<void> writeTare();
  Future<void> timer(TimerMode start);
  Future<void> display(DisplayMode start);
  Future<void> power(PowerMode start);
  Future<void> beep();
}
