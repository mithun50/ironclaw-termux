/**
 * IronClaw Installer - Handles environment setup for Termux
 */

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';

const HOME = process.env.HOME || '/data/data/com.termux/files/home';
const PROOT_ROOTFS = '/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs';
const PROOT_UBUNTU_ROOT = path.join(PROOT_ROOTFS, 'ubuntu', 'root');

export function checkDependencies() {
  const deps = {
    git: false,
    proot: false
  };

  try {
    execSync('git --version', { stdio: 'pipe' });
    deps.git = true;
  } catch { /* not installed */ }

  try {
    execSync('which proot-distro', { stdio: 'pipe' });
    deps.proot = true;
  } catch { /* not installed */ }

  return deps;
}

export function configureTermux() {
  console.log('Configuring Termux for background operation...');

  const ironclawDir = path.join(HOME, '.ironclaw');
  if (!fs.existsSync(ironclawDir)) {
    fs.mkdirSync(ironclawDir, { recursive: true });
  }

  const wakeLockScript = path.join(ironclawDir, 'wakelock.sh');
  const wakeLockContent = `#!/bin/bash
# Keep Termux awake while IronClaw runs
termux-wake-lock
trap "termux-wake-unlock" EXIT
exec "$@"
`;

  fs.writeFileSync(wakeLockScript, wakeLockContent, 'utf8');
  fs.chmodSync(wakeLockScript, '755');

  console.log('Wake-lock script created');
  console.log('');
  console.log('IMPORTANT: Disable battery optimization for Termux in Android settings!');

  return true;
}

export function getInstallStatus() {
  // Check proot-distro
  let hasProot = false;
  try {
    execSync('command -v proot-distro', { stdio: 'pipe' });
    hasProot = true;
  } catch { /* not installed */ }

  // Check if ubuntu is installed by checking rootfs directory
  let hasUbuntu = false;
  try {
    hasUbuntu = fs.existsSync(path.join(PROOT_ROOTFS, 'ubuntu'));
  } catch { /* check failed */ }

  // Check Rust/cargo in proot ubuntu
  let hasRustInProot = false;
  if (hasUbuntu) {
    try {
      hasRustInProot = fs.existsSync(path.join(PROOT_UBUNTU_ROOT, '.cargo', 'bin', 'cargo'));
    } catch { /* check failed */ }
  }

  // Check if ironclaw binary exists in proot ubuntu
  let hasIronClawInProot = false;
  if (hasUbuntu) {
    try {
      // Primary: check cargo bin directly on filesystem
      const ironclawBin = path.join(PROOT_UBUNTU_ROOT, '.cargo', 'bin', 'ironclaw');
      hasIronClawInProot = fs.existsSync(ironclawBin);
    } catch { /* check failed */ }

    // Fallback: ask proot
    if (!hasIronClawInProot) {
      try {
        execSync('proot-distro login ubuntu -- bash -lc "command -v ironclaw"', { stdio: 'pipe', timeout: 30000 });
        hasIronClawInProot = true;
      } catch { /* not installed */ }
    }
  }

  return {
    proot: hasProot,
    ubuntu: hasUbuntu,
    rustInProot: hasRustInProot,
    ironClawInProot: hasIronClawInProot,
  };
}

export function installProot() {
  console.log('Installing proot-distro...');
  try {
    execSync('pkg install -y proot-distro', { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install proot-distro:', err.message);
    return false;
  }
}

export function installUbuntu() {
  console.log('Installing Ubuntu in proot (this may take a while)...');
  try {
    execSync('proot-distro install ubuntu', { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install Ubuntu:', err.message);
    return false;
  }
}

export function setupProotUbuntu() {
  console.log('Setting up Rust and IronClaw in Ubuntu...');

  const setupScript = `
    apt-get update -y && apt-get upgrade -y
    apt-get install -y curl wget git build-essential pkg-config libssl-dev libsqlite3-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
    cargo install --git https://github.com/JoasASantos/ironclaw --locked
  `;

  try {
    execSync(`proot-distro login ubuntu -- bash -c '${setupScript}'`, { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to setup Ubuntu:', err.message);
    return false;
  }
}

export function runInProot(command) {
  // Set PATH to include cargo bin so ironclaw is found
  const env = 'export PATH="$HOME/.cargo/bin:$PATH"';
  return spawn('proot-distro', ['login', 'ubuntu', '--', 'bash', '-c', `${env} && ${command}`], {
    stdio: 'inherit'
  });
}

export function runInProotWithCallback(command, onFirstOutput) {
  const env = 'export PATH="$HOME/.cargo/bin:$PATH"';
  let firstOutput = true;

  const proc = spawn('proot-distro', ['login', 'ubuntu', '--', 'bash', '-c', `${env} && ${command}`], {
    stdio: ['inherit', 'pipe', 'pipe']
  });

  proc.stdout.on('data', (data) => {
    if (firstOutput) {
      firstOutput = false;
      onFirstOutput();
    }
    process.stdout.write(data);
  });

  proc.stderr.on('data', (data) => {
    if (firstOutput) {
      firstOutput = false;
      onFirstOutput();
    }
    const str = data.toString();
    if (!str.includes('proot warning') && !str.includes("can't sanitize")) {
      process.stderr.write(data);
    }
  });

  return proc;
}
