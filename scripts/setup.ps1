# =============================================================================
#  setup.ps1 — installation en une commande (Windows PowerShell)
#  Vérifie les prérequis, lance les services Docker, installe l'API,
#  applique la base de données via Prisma. Ne touche jamais aux données existantes.
#  Usage : powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
# =============================================================================
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

function Say($msg)  { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "✔ $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "✘ $msg" -ForegroundColor Red; exit 1 }

# ── 1. Prérequis ────────────────────────────────────────────────────────────
Say "Vérification des prérequis"
try { docker --version     | Out-Null } catch { Fail "Docker absent — installez Docker Desktop: https://www.docker.com/products/docker-desktop/" }
try { docker compose version | Out-Null } catch { Fail "Docker Compose v2 requis (livré avec Docker Desktop récent)." }
try { node --version       | Out-Null } catch { Fail "Node.js 20+ absent — https://nodejs.org/" }
try { npm --version        | Out-Null } catch { Fail "npm absent (installé avec Node)." }
$nodeMajor = [int]((node -p "process.versions.node.split('.')[0]"))
if ($nodeMajor -lt 20) { Fail "Node 20+ requis (vous avez $(node -v))." }
try { flutter --version | Out-Null } catch { Write-Host "  Flutter non trouvé — requis plus tard pour apps/app (https://docs.flutter.dev)." }
Ok "Prérequis OK (Node $(node -v))"

# ── 2. Fichiers d'environnement ────────────────────────────────────────────
Say "Fichiers .env"
if (-not (Test-Path .env))        { Copy-Item .env.example .env; Ok ".env créé" }
if (-not (Test-Path apps/api/.env)) { Copy-Item apps/api/.env.example apps/api/.env; Ok "apps/api/.env créé" }

# ── 2 bis. Config Garage (secrets aléatoires, une seule fois) ─────────────
Say "Config Garage (docker/garage.toml)"
if (-not (Test-Path docker/garage.toml)) {
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $bytes = New-Object byte[] 32
  $rng.GetBytes($bytes)
  $rpcHex = -join ($bytes | ForEach-Object { $_.ToString("x2") })
  $rng.GetBytes($bytes)
  $adminTok   = [Convert]::ToBase64String($bytes).Replace("/","").Replace("+","").Replace("=","")
  $rng.GetBytes($bytes)
  $metricsTok = [Convert]::ToBase64String($bytes).Replace("/","").Replace("+","").Replace("=","")
  $content = Get-Content docker/garage.toml.example -Raw
  $content = $content.Replace("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef", $rpcHex)
  $content = $content.Replace("dev_admin_token_0000000000000000", $adminTok)
  $content = $content.Replace("dev_metrics_token_00000000000000", $metricsTok)
  # UTF-8 sans BOM (le parseur TOML de Garage n'apprécie pas les BOM)
  [System.IO.File]::WriteAllText((Join-Path (Get-Location) "docker/garage.toml"), $content)
  Ok "docker/garage.toml généré (secrets aléatoires)"
} else {
  Write-Host "  docker/garage.toml déjà présent (inchangé)"
}

# ── 3. Services Docker ─────────────────────────────────────────────────────
Say "Démarrage des services (PostgreSQL, Redis, Garage, MailPit)"
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "docker compose up a échoué" }
Say "Attente de santé des services (jusqu'à 60 s)"
for ($i = 0; $i -lt 30; $i++) {
  $healthy = (docker compose ps --status healthy -q | Measure-Object).Count
  if ($healthy -ge 3) { break }
  Start-Sleep -Seconds 2
}
docker compose ps
Ok "Services prêts"

# ── 4. API : dépendances + Prisma ──────────────────────────────────────────
Say "Installation de l'API (npm install)"
Set-Location apps/api
if (-not (Test-Path node_modules)) { npm install --no-audit --no-fund }
if ($LASTEXITCODE -ne 0) { Fail "npm install a échoué" }
Say "Génération du client Prisma"
npx prisma generate
Say "Application du schéma à la base (migration initiale)"
npx prisma migrate dev

# ── 5. Suite ───────────────────────────────────────────────────────────────
Say "L'API peut maintenant être démarrée :"
Write-Host "  cd apps\api ; npm run start:dev"
Write-Host "  → santé : http://localhost:3000/health"
Write-Host "  → Swagger : http://localhost:3000/docs"
Write-Host ""
Write-Host "Flutter (nouveau terminal) :"
Write-Host "  cd apps\app ; flutter create . --platforms android,windows ; flutter run"
Ok "Installation terminée"
