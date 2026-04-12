class AppConstants {
  static const String appName = 'IronClaw';
  static const String version = '1.8.7';
  static const String packageName = 'com.nxg.ironclawproot';

  /// Matches ANSI escape sequences (e.g. color codes in terminal output).
  static final ansiEscape = RegExp(r'\x1b\[[0-9;]*[a-zA-Z]');

  static const String authorName = 'Mithun Gowda B';
  static const String authorEmail = 'mithungowda.b7411@gmail.com';
  static const String githubUrl = 'https://github.com/mithun50/ironclaw-termux';
  static const String license = 'MIT';

  static const String githubApiLatestRelease =
      'https://api.github.com/repos/mithun50/ironclaw-termux/releases/latest';

  // NextGenX
  static const String orgName = 'NextGenX';
  static const String orgEmail = 'nxgextra@gmail.com';
  static const String instagramUrl = 'https://www.instagram.com/nexgenxplorer_nxg';
  static const String youtubeUrl = 'https://youtube.com/@nexgenxplorer?si=UG-wBC8UIyeT4bbw';
  static const String playStoreUrl = 'https://play.google.com/store/apps/dev?id=8262374975871504599';

  static const String gatewayHost = '127.0.0.1';
  static const int gatewayPort = 3000;
  static const String gatewayUrl = 'http://$gatewayHost:$gatewayPort';

  static const String ubuntuRootfsUrl =
      'https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.3-base-';
  static const String rootfsArm64 = '${ubuntuRootfsUrl}arm64.tar.gz';
  static const String rootfsArmhf = '${ubuntuRootfsUrl}armhf.tar.gz';
  static const String rootfsAmd64 = '${ubuntuRootfsUrl}amd64.tar.gz';

  // Rust toolchain installer
  static const String rustupUrl = 'https://sh.rustup.rs';

  static const int healthCheckIntervalMs = 5000;
  static const int maxAutoRestarts = 5;

  // Node constants
  static const int wsReconnectBaseMs = 350;
  static const double wsReconnectMultiplier = 1.7;
  static const int wsReconnectCapMs = 8000;
  static const String nodeRole = 'node';
  static const int pairingTimeoutMs = 300000;

  static const String channelName = 'com.nxg.ironclawproot/native';
  static const String eventChannelName = 'com.nxg.ironclawproot/gateway_logs';

  static String getRootfsUrl(String arch) {
    switch (arch) {
      case 'aarch64':
        return rootfsArm64;
      case 'arm':
        return rootfsArmhf;
      case 'x86_64':
        return rootfsAmd64;
      default:
        return rootfsArm64;
    }
  }
}
