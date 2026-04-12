/**
 * Post-install script - runs after npm install
 */

import { isAndroid } from './bionic-bypass.js';

function main() {
  console.log('\n🦾 IronClaw-Termux post-install\n');

  if (!isAndroid()) {
    console.log('Not running on Android/Termux — skipping setup.');
    console.log('Run ironclawx setup on your Android device.\n');
    return;
  }

  console.log('\n' + '═'.repeat(50));
  console.log('IronClaw-Termux installed!');
  console.log('═'.repeat(50));
  console.log('\nNext step: run full setup\n');
  console.log('  ironclawx setup');
  console.log('\nThis will install proot Ubuntu + Rust + IronClaw.');
  console.log('═'.repeat(50) + '\n');
}

main();

