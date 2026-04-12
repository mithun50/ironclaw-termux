import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/setup_state.dart';
import 'native_bridge.dart';

class BootstrapService {
  final Dio _dio = Dio();

  void _updateSetupNotification(String text, {int progress = -1}) {
    try {
      NativeBridge.updateSetupNotification(text, progress: progress);
    } catch (_) {}
  }

  void _stopSetupService() {
    try {
      NativeBridge.stopSetupService();
    } catch (_) {}
  }

  Future<SetupState> checkStatus() async {
    try {
      final complete = await NativeBridge.isBootstrapComplete();
      if (complete) {
        return const SetupState(
          step: SetupStep.complete,
          progress: 1.0,
          message: 'Setup complete',
        );
      }
      return const SetupState(
        step: SetupStep.checkingStatus,
        progress: 0.0,
        message: 'Setup required',
      );
    } catch (e) {
      return SetupState(
        step: SetupStep.error,
        error: 'Failed to check status: $e',
      );
    }
  }

  Future<void> runFullSetup({
    required void Function(SetupState) onProgress,
  }) async {
    try {
      try {
        await NativeBridge.startSetupService();
      } catch (_) {}

      // Step 0: Setup directories
      onProgress(const SetupState(
        step: SetupStep.checkingStatus,
        progress: 0.0,
        message: 'Setting up directories...',
      ));
      _updateSetupNotification('Setting up directories...', progress: 2);
      try { await NativeBridge.setupDirs(); } catch (_) {}
      try { await NativeBridge.writeResolv(); } catch (_) {}

      // Step 1: Download rootfs
      final arch = await NativeBridge.getArch();
      final rootfsUrl = AppConstants.getRootfsUrl(arch);
      final filesDir = await NativeBridge.getFilesDir();

      const resolvContent = 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n';
      try {
        final configDir = '$filesDir/config';
        final resolvFile = File('$configDir/resolv.conf');
        if (!resolvFile.existsSync()) {
          Directory(configDir).createSync(recursive: true);
          resolvFile.writeAsStringSync(resolvContent);
        }
        final rootfsResolv = File('$filesDir/rootfs/ubuntu/etc/resolv.conf');
        if (!rootfsResolv.existsSync()) {
          rootfsResolv.parent.createSync(recursive: true);
          rootfsResolv.writeAsStringSync(resolvContent);
        }
      } catch (_) {}
      final tarPath = '$filesDir/tmp/ubuntu-rootfs.tar.gz';

      _updateSetupNotification('Downloading Ubuntu rootfs...', progress: 5);
      onProgress(const SetupState(
        step: SetupStep.downloadingRootfs,
        progress: 0.0,
        message: 'Downloading Ubuntu rootfs...',
      ));

      await _dio.download(
        rootfsUrl,
        tarPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            final mb = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
            final notifProgress = 5 + (progress * 25).round();
            _updateSetupNotification('Downloading rootfs: $mb / $totalMb MB', progress: notifProgress);
            onProgress(SetupState(
              step: SetupStep.downloadingRootfs,
              progress: progress,
              message: 'Downloading: $mb MB / $totalMb MB',
            ));
          }
        },
      );

      // Step 2: Extract rootfs (30-45%)
      _updateSetupNotification('Extracting rootfs...', progress: 30);
      onProgress(const SetupState(
        step: SetupStep.extractingRootfs,
        progress: 0.0,
        message: 'Extracting rootfs (this takes a while)...',
      ));
      await NativeBridge.extractRootfs(tarPath);
      onProgress(const SetupState(
        step: SetupStep.extractingRootfs,
        progress: 1.0,
        message: 'Rootfs extracted',
      ));

      // Step 3: Fix permissions and install build tools (45-55%)
      _updateSetupNotification('Fixing rootfs permissions...', progress: 45);
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 0.0,
        message: 'Fixing rootfs permissions...',
      ));
      await NativeBridge.runInProot(
        'chmod -R 755 /usr/bin /usr/sbin /bin /sbin '
        '/usr/local/bin /usr/local/sbin 2>/dev/null; '
        'chmod -R +x /usr/lib/apt/ /usr/lib/dpkg/ /usr/libexec/ '
        '/var/lib/dpkg/info/ /usr/share/debconf/ 2>/dev/null; '
        'chmod 755 /lib/*/ld-linux-*.so* /usr/lib/*/ld-linux-*.so* 2>/dev/null; '
        'mkdir -p /var/lib/dpkg/updates /var/lib/dpkg/triggers; '
        'echo permissions_fixed',
      );

      _updateSetupNotification('Updating package lists...', progress: 48);
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 0.1,
        message: 'Updating package lists...',
      ));
      await NativeBridge.runInProot('apt-get update -y');

      _updateSetupNotification('Installing build tools...', progress: 52);
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 0.2,
        message: 'Installing build tools...',
      ));
      await NativeBridge.runInProot(
        'ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime && '
        'echo "Etc/UTC" > /etc/timezone',
      );
      await NativeBridge.runInProot(
        'apt-get install -y --no-install-recommends '
        'ca-certificates git curl wget build-essential pkg-config '
        'libssl-dev libsqlite3-dev',
      );

      // Step 4: Install Rust toolchain (55-75%)
      _updateSetupNotification('Installing Rust toolchain...', progress: 55);
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 0.4,
        message: 'Installing Rust toolchain (this may take a few minutes)...',
      ));
      await NativeBridge.runInProot(
        r"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path",
        timeout: 600,
      );

      _updateSetupNotification('Verifying Rust...', progress: 74);
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 0.9,
        message: 'Verifying Rust...',
      ));
      await NativeBridge.runInProot(
        r'source "$HOME/.cargo/env" && rustc --version && cargo --version',
      );
      onProgress(const SetupState(
        step: SetupStep.installingRust,
        progress: 1.0,
        message: 'Rust installed',
      ));

      // Step 5: Install IronClaw via cargo (75-98%)
      _updateSetupNotification('Installing IronClaw...', progress: 76);
      onProgress(const SetupState(
        step: SetupStep.installingIronClaw,
        progress: 0.0,
        message: 'Building IronClaw from source (this takes several minutes)...',
      ));
      await NativeBridge.runInProot(
        r'source "$HOME/.cargo/env" && '
        'cargo install --git https://github.com/JoasASantos/ironclaw --locked',
        timeout: 3600,
      );

      _updateSetupNotification('Verifying IronClaw...', progress: 96);
      onProgress(const SetupState(
        step: SetupStep.installingIronClaw,
        progress: 0.9,
        message: 'Verifying IronClaw...',
      ));
      await NativeBridge.runInProot(
        r'source "$HOME/.cargo/env" && ironclaw --version || echo ironclaw_installed',
      );
      onProgress(const SetupState(
        step: SetupStep.installingIronClaw,
        progress: 1.0,
        message: 'IronClaw installed',
      ));

      // Done
      _updateSetupNotification('Setup complete!', progress: 100);
      _stopSetupService();
      onProgress(const SetupState(
        step: SetupStep.complete,
        progress: 1.0,
        message: 'Setup complete! Ready to start IronClaw.',
      ));
    } on DioException catch (e) {
      _stopSetupService();
      onProgress(SetupState(
        step: SetupStep.error,
        error: 'Download failed: ${e.message}. Check your internet connection.',
      ));
    } catch (e) {
      _stopSetupService();
      onProgress(SetupState(
        step: SetupStep.error,
        error: 'Setup failed: $e',
      ));
    }
  }
}
