/**
 * IronClaw-Termux - Main entry point
 */

import {
  configureTermux,
  getInstallStatus,
  installProot,
  installUbuntu,
  setupProotUbuntu,
  runInProot
} from './installer.js';
import { isAndroid } from './bionic-bypass.js';
import { spawn } from 'child_process';

const VERSION = '1.8.7';

function printBanner() {
  console.log(`
╔═══════════════════════════════════════════╗
║     IronClaw-Termux v${VERSION}              ║
║     AI Agent Framework for Android        ║
╚═══════════════════════════════════════════╝
`);
}

function printHelp() {
  console.log(`
Usage: ironclawx <command> [args...]

Commands:
  setup       Full installation (proot + Ubuntu + Rust + IronClaw)
  status      Check installation status
  start       Start IronClaw agent with web UI (inside proot)
  shell       Open Ubuntu shell with IronClaw ready
  help        Show this help message

  Any other command is passed directly to ironclaw in proot:
    ironclawx onboard               → ironclaw onboard
    ironclawx run --provider fast   → ironclaw run --provider fast
    ironclawx doctor                → ironclaw doctor
    ironclawx models                → ironclaw models --available
    ironclawx policy                → ironclaw policy
    ironclawx audit --count 50      → ironclaw audit --count 50
    ironclawx skill list            → ironclaw skill list

Presets (no API key needed for local):
  ironclawx run --provider local    # Ollama (free, local)
  ironclawx run --provider fast     # Groq (ultra-fast)
  ironclawx run --provider smart    # Anthropic Claude
  ironclawx run --provider cheap    # DeepSeek

Examples:
  ironclawx setup                   # First-time setup
  ironclawx start                   # Start agent + web UI on port 3000
  ironclawx onboard                 # Interactive config wizard
  ironclawx shell                   # Enter Ubuntu shell
`);
}

async function runSetup() {
  console.log('Starting IronClaw setup for Termux...\n');
  console.log('This will install: proot-distro → Ubuntu → build-essential → Rust → IronClaw\n');
  console.log('⚠  Building IronClaw from source with cargo can take 15-30 min on Android ARM.\n');
  console.log('   Ensure ~2 GB free disk space and keep the screen awake.\n');

  if (!isAndroid()) {
    console.log('Warning: This package is designed for Android/Termux.');
    console.log('Some features may not work on other platforms.\n');
  }

  let status = getInstallStatus();

  // Step 1: Install proot-distro
  console.log('[1/4] Checking proot-distro...');
  if (!status.proot) {
    console.log('  Installing proot-distro...');
    installProot();
  } else {
    console.log('  ✓ proot-distro installed');
  }
  console.log('');

  // Step 2: Install Ubuntu
  console.log('[2/4] Checking Ubuntu in proot...');
  status = getInstallStatus();
  if (!status.ubuntu) {
    console.log('  Installing Ubuntu (this takes a while)...');
    installUbuntu();
  } else {
    console.log('  ✓ Ubuntu installed');
  }
  console.log('');

  // Step 3: Setup Rust and IronClaw in Ubuntu
  console.log('[3/4] Setting up Rust and IronClaw in Ubuntu...');
  status = getInstallStatus();
  if (!status.ironClawInProot) {
    setupProotUbuntu();
  } else {
    console.log('  ✓ IronClaw already installed in proot');
  }
  console.log('');

  // Step 4: Configure Termux wake-lock
  console.log('[4/4] Configuring Termux...');
  configureTermux();
  console.log('');

  // Done
  console.log('═══════════════════════════════════════════');
  console.log('Setup complete!');
  console.log('');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Configure:  ironclawx onboard');
  console.log('     → Interactive wizard: pick provider, paste API key, save ironclaw.yaml');
  console.log('  2. Start:      ironclawx start');
  console.log('     → Runs ironclaw with web UI at http://127.0.0.1:3000');
  console.log('');
  console.log('Quick start (no API key — local Ollama):');
  console.log('  ironclawx run --provider local --ui');
  console.log('');
  console.log('Diagnostics: ironclawx doctor');
  console.log('═══════════════════════════════════════════');
}

function showStatus() {
  process.stdout.write('Checking installation status...');
  const status = getInstallStatus();
  process.stdout.write('\r' + ' '.repeat(35) + '\r');

  console.log('Installation Status:\n');

  console.log('Termux:');
  console.log(`  proot-distro:     ${status.proot ? '✓ installed' : '✗ missing'}`);
  console.log(`  Ubuntu (proot):   ${status.ubuntu ? '✓ installed' : '✗ not installed'}`);
  console.log('');

  if (status.ubuntu) {
    console.log('Inside Ubuntu:');
    console.log(`  Rust/Cargo:       ${status.rustInProot ? '✓ installed' : '✗ not installed'}`);
    console.log(`  IronClaw:         ${status.ironClawInProot ? '✓ installed' : '✗ not installed'}`);
    console.log('');
  }

  if (status.proot && status.ubuntu && status.ironClawInProot) {
    console.log('Status: ✓ Ready to run!');
    console.log('');
    console.log('Commands:');
    console.log('  ironclawx start       # Start agent');
    console.log('  ironclawx onboard     # Configure API keys');
    console.log('  ironclawx shell       # Enter Ubuntu shell');
  } else {
    console.log('Status: ✗ Setup incomplete');
    console.log('Run: ironclawx setup');
  }
}

function startAgent() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu) {
    console.error('proot/Ubuntu not installed. Run: ironclawx setup');
    process.exit(1);
  }

  if (!status.ironClawInProot) {
    console.error('IronClaw not installed in proot. Run: ironclawx setup');
    process.exit(1);
  }

  const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  let i = 0;
  let started = false;
  const UI_URL = 'http://127.0.0.1:3000';

  const spinner = setInterval(() => {
    if (!started) {
      process.stdout.write(`\r${frames[i++ % frames.length]} Starting IronClaw agent...`);
    }
  }, 80);

  const checkUI = setInterval(async () => {
    if (started) return;
    try {
      const response = await fetch(UI_URL, { method: 'HEAD', signal: AbortSignal.timeout(1000) });
      if (response.ok || response.status < 500) {
        started = true;
        clearInterval(spinner);
        clearInterval(checkUI);
        process.stdout.write('\r' + ' '.repeat(40) + '\r');
        console.log('✓ IronClaw agent started!\n');
        console.log(`Web UI: ${UI_URL}`);
        console.log('Press Ctrl+C to stop\n');
        console.log('─'.repeat(45) + '\n');
      }
    } catch { /* ignore polling errors */ }
  }, 500);

  const agent = runInProot('bash -lc "ironclaw run --ui"');

  agent.on('error', (err) => {
    clearInterval(spinner);
    clearInterval(checkUI);
    console.error('\nFailed to start agent:', err.message);
  });

  agent.on('close', (code) => {
    clearInterval(spinner);
    clearInterval(checkUI);
    if (!started) {
      console.log('\nAgent exited before starting. Run: ironclawx onboard');
    }
    console.log(`Agent exited with code ${code}`);
  });
}

function runIronclawCommand(args) {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu || !status.ironClawInProot) {
    console.error('Setup not complete. Run: ironclawx setup');
    process.exit(1);
  }

  const command = args.join(' ');
  console.log(`Running: ironclaw ${command}\n`);

  if (args[0] === 'onboard') {
    console.log('TIP: The onboarding wizard will guide you through provider and API key setup!\n');
  }

  const proc = runInProot(`bash -lc "ironclaw ${command}"`);

  proc.on('error', (err) => {
    console.error('Failed to run command:', err.message);
  });
}

function openShell() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu) {
    console.error('proot/Ubuntu not installed. Run: ironclawx setup');
    process.exit(1);
  }

  console.log('Entering Ubuntu shell (IronClaw ready)...');
  console.log('Type "exit" to return to Termux\n');

  const shell = spawn('proot-distro', ['login', 'ubuntu'], {
    stdio: 'inherit'
  });

  shell.on('error', (err) => {
    console.error('Failed to open shell:', err.message);
  });
}

export async function main(args) {
  const command = args[0] || 'help';

  printBanner();

  switch (command) {
    case 'setup':
    case 'install':
      await runSetup();
      break;

    case 'status':
      showStatus();
      break;

    case 'start':
    case 'run':
      startAgent();
      break;

    case 'shell':
    case 'ubuntu':
      openShell();
      break;

    case 'help':
    case '--help':
    case '-h':
      printHelp();
      break;

    default:
      // Pass any other command to ironclaw in proot
      runIronclawCommand(args);
      break;
  }
}
