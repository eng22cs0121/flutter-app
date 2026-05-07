# MediTrustChain – Patient Flutter App

A native Android app that replicates the Patient Web Page functionality of MediTrustChain, allowing patients to verify medicine authenticity via QR code scanning and blockchain verification.

---

## Features

| Feature | Details |
|---------|---------|
| QR Code Scanner | Real-time camera scanning using device back camera |
| Manual Entry | Enter batch code (e.g. `BCH-001`) manually |
| Blockchain Verification | Queries Sepolia Ethereum testnet via JSON-RPC |
| Supabase Fallback | Falls back to Supabase DB if blockchain is unavailable |
| Scan History | Persists last 50 verifications locally on device |
| Status Display | GENUINE / TAMPERED / EXPIRED / RECALLED / NOT APPROVED / NOT FOUND |
| Supply Chain Details | Full batch info: drug name, manufacturer, dates, holder, location |
| Dark Theme | Matches the web app's design system |

---

## Getting the APK (No Setup Required)

### Option A — GitHub Actions (Recommended)

1. Push this repository to GitHub
2. GitHub Actions automatically builds the APK on every push to `main`/`master`
3. Download the APK from one of two places:

**Permanent Release link** (created automatically):
```
https://github.com/YOUR_USERNAME/YOUR_REPO/releases/latest
```

**Workflow artifact** (90-day retention):
```
https://github.com/YOUR_USERNAME/YOUR_REPO/actions
→ Click the latest "Build Android APK" run
→ Scroll to "Artifacts" section
→ Download "MediTrust-Patient-APK"
```

### Option B — Build Locally

#### Prerequisites
- Flutter SDK 3.22+ → https://docs.flutter.dev/get-started/install
- Android Studio / SDK (API 21+)
- Java 17

#### Steps
```bash
# 1. Navigate to this folder
cd FLUTTER-APP

# 2. Install dependencies
flutter pub get

# 3. Build release APK
flutter build apk --release

# 4. Find the APK at:
#    build/app/outputs/flutter-apk/app-release.apk
```

---

## Installing the APK on Android

1. **Enable Unknown Sources**: Go to `Settings → Security → Install unknown apps` and enable for your browser/file manager
2. **Download** the APK file to your phone
3. **Open** the APK file — Android will prompt you to install
4. **Tap Install** and wait for installation to complete
5. Open **MediTrustChain** from your app drawer

> Minimum requirement: Android 5.0 (API 21)

---

## Project Structure

```
FLUTTER-APP/
├── .github/workflows/build-apk.yml    # CI/CD – auto-build APK on push
├── android/                            # Android project files
├── assets/images/                      # App assets
└── lib/
    ├── main.dart                       # App entry point + theme
    ├── config/
    │   └── constants.dart              # Supabase URL, contract address, etc.
    ├── models/
    │   ├── batch.dart                  # Batch & history data models
    │   └── verification_result.dart    # Verification result types
    ├── services/
    │   ├── blockchain_service.dart     # Ethereum RPC + contract calls
    │   ├── supabase_service.dart       # Supabase queries (fallback)
    │   └── scan_history_service.dart   # Local scan history (SharedPrefs)
    ├── screens/
    │   ├── main_screen.dart            # Bottom nav container
    │   ├── verify_screen.dart          # QR scan + manual verify
    │   ├── history_screen.dart         # Past scans list
    │   └── about_screen.dart           # App info + how it works
    └── widgets/
        └── verification_result_card.dart  # Result display widget
```

---

## Configuration

All configuration is in `lib/config/constants.dart`:

| Constant | Value | Description |
|----------|-------|-------------|
| `supabaseUrl` | `https://idmmiqypcjxejoyyhahj.supabase.co` | Supabase project URL |
| `supabaseAnonKey` | `eyJ...` | Supabase anonymous key (safe to expose) |
| `contractAddress` | `0x1E60...` | MediTrustChainV2 contract on Sepolia |
| `rpcUrl` | `https://eth-sepolia.g.alchemy.com/v2/demo` | Sepolia JSON-RPC endpoint |

> **Production Note**: Replace the Alchemy `demo` key with a real API key from https://alchemy.com for reliable blockchain access.

---

## Verification Logic

The app mirrors the web app's `verifyBatchOnBlockchain()` function exactly:

1. **Parse QR code** — JSON payload or plain batch code string
2. **Fetch batch ID** from contract via `getBatchIdByCode(batchCode)`
3. **Get full batch data** via `getBatchFull(batchId)` — returns BatchCore + BatchState structs
4. **Hash comparison** — if QR contains `dataHash`, compare with on-chain `BatchCore.dataHash`
5. **Contract verification** — call `verifyBatchWithHash(batchId, hash)` which returns `(isGenuine, status)`
6. **Return result** — GENUINE / TAMPERED / EXPIRED / RECALLED / NOT_APPROVED
7. **Fallback** — if blockchain unavailable, query Supabase `batches` table

---

## API Integration

### Smart Contract (Sepolia)
- `getBatchIdByCode(string batchCode) → uint256`
- `getBatchFull(uint256 batchId) → (BatchCore, BatchState)`
- `verifyBatchWithHash(uint256 batchId, bytes32 hash) → (bool, string)`

### Supabase Tables (Read-Only)
- `batches` — batch data including status, expiry, manufacturer
- `batch_history` — supply chain journey events

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `mobile_scanner` | QR code / barcode scanning |
| `web3dart` | Ethereum JSON-RPC + ABI encoding |
| `supabase_flutter` | Supabase client |
| `shared_preferences` | Local scan history persistence |
| `google_fonts` | Inter font (matches web design) |
| `url_launcher` | Open blockchain explorer links |
| `intl` | Date formatting |
| `uuid` | Unique IDs for history entries |
| `convert` | Hex encoding for bytes32 |
