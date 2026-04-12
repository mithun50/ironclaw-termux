/**
 * Bionic Bypass - Legacy shim (not required by IronClaw)
 *
 * IronClaw is a native Rust binary and does not use Node.js
 * os.networkInterfaces(), so this bypass is not needed.
 *
 * Kept for reference / backwards compatibility only.
 */

import fs from 'fs';
import path from 'path';

export function isAndroid() {
  return process.platform === 'android' ||
         fs.existsSync('/data/data/com.termux') ||
         process.env.TERMUX_VERSION !== undefined;
}

export function getBypassScriptPath() {
  const homeDir = process.env.HOME || '/data/data/com.termux/files/home';
  return path.join(homeDir, '.ironclaw', 'bionic-bypass.js');
}

// No-op: IronClaw does not need the bionic bypass shim.
export function installBypass() {
  return getBypassScriptPath();
}

export function checkBypassInstalled() {
  return false;
}

