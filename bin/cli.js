#!/usr/bin/env node

const path = require('path');
const { spawnSync } = require('child_process');

const userShell = process.env.SHELL || '';
const isFish = /fish/i.test(userShell);

const installerName = isFish ? 'install.fish' : 'install.sh';
const installerPath = path.join(__dirname, '..', 'scripts', installerName);
const shellCmd = isFish ? 'fish' : 'bash';
const args = process.argv.slice(2);

console.log('🚀 Starte Setup für mal-agents...');
console.log(isFish
  ? '🐟 Fish Shell erkannt. Starte Fish-Installer...'
  : '🐚 Bash/Zsh erkannt. Starte Bash-Installer...');

const result = spawnSync(shellCmd, [installerPath, ...args], { stdio: 'inherit' });

if (result.error) {
  console.error('❌ Fehler beim Ausführen des Installers:', result.error.message);
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);
