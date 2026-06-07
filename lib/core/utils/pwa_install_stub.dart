bool isPwaInstallAvailable() => false;
bool isPwaRunningStandalone() => false;
bool isIosSafari() => false;
Future<void> showPwaInstallPrompt() async {}
void registerPwaCallbacks({required void Function() onAvailable, required void Function() onInstalled}) {}
