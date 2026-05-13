<div align="center">

# 💊 MediTrustChain — Patient App

### *Verify Medicine Authenticity with Blockchain*

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-5.0+-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Flutter-3ECF8E?style=for-the-badge&logo=supabase)](https://supabase.com/)
[![Ethereum](https://img.shields.io/badge/Ethereum-Sepolia-627EEA?style=for-the-badge&logo=ethereum)](https://sepolia.etherscan.io/)

**Part of the MediTrustChain Final Year Project** — A Flutter patient app that lets anyone scan or enter a batch ID to instantly verify whether a medicine is genuine, traceable on the blockchain, and not expired.

[📦 Download APK](#-download-apk) · [🚀 Build Locally](#️-build-locally) · [🔗 Main Project](https://github.com/eng22cs0121/FINAL-YEAR-PROJECT)

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 **Manual Verify** | Type a batch ID (e.g. `BCH-0010`) to check authenticity |
| 📷 **QR Code Scan** | Use camera to scan batch QR codes instantly |
| ⛓️ **Blockchain Proof** | Reads directly from Ethereum Sepolia smart contract |
| 🗺️ **Supply Chain Trail** | Shows every step — Manufacturer → Regulator → Logistics → Pharmacy |
| 📋 **Scan History** | Locally stores your last 50 verifications |
| 🌙 **Dark Theme** | Material 3 dark theme with teal accent |
| ⚡ **Offline Fallback** | Falls back to Supabase if blockchain is unavailable |

---

## 🔄 Verification Flow

```
 Patient opens app
        │
        ▼
 Enter Batch ID / Scan QR
        │
        ▼
 ┌──────────────────────┐
 │  Read Smart Contract │  ◄── Ethereum Sepolia RPC
 │  (Primary source)    │
 └──────────┬───────────┘
            │  Success?
      ┌─────┴──────┐
     YES           NO
      │             │
      ▼             ▼
 Show on-chain   Fallback to
 verified data   Supabase DB
      │             │
      └──────┬───────┘
             ▼
     ┌───────────────┐
     │ Authenticity  │
     │    Result     │
     ├───────────────┤
     │ ✅ GENUINE    │  Drug name, manufacturer, expiry,
     │ ❌ COUNTERFEIT│  supply chain history, blockchain tx
     │ ⚠️ EXPIRED    │
     └───────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.22 |
| **Language** | Dart 3.4 |
| **Blockchain** | `web3dart` — direct RPC calls to Sepolia |
| **Database** | `supabase_flutter` — fallback queries |
| **QR Scanning** | `mobile_scanner` |
| **Local Storage** | `shared_preferences` — scan history |
| **UI** | Material 3, Dark theme, Teal accent |
| **Min SDK** | Android 5.0 (API 21) |

---

## 📦 Download APK

Download the latest pre-built APK from:

```
https://github.com/eng22cs0121/flutter-app/releases/latest
```

---

## 🏗️ Build Locally

### Prerequisites

- [Flutter SDK 3.22+](https://docs.flutter.dev/get-started/install)
- Android Studio / SDK (API 21+)
- Java 17

### Steps

```bash
# 1. Clone
git clone https://github.com/eng22cs0121/flutter-app.git
cd flutter-app

# 2. Get dependencies
flutter pub get

# 3. Run on connected device
flutter run

# 4. Build release APK
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚙️ Configuration

Edit [`lib/config/constants.dart`](lib/config/constants.dart):

```dart
class AppConstants {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String contractAddress = '0x...your_contract_address';
  static const String rpcUrl = 'https://eth-sepolia.g.alchemy.com/v2/demo';
}
```

---

## 📁 Project Structure

```
flutter-app/
├── lib/
│   ├── main.dart                        # App entry + dark theme
│   ├── config/
│   │   └── constants.dart               # Supabase URL, contract, RPC config
│   ├── models/
│   │   ├── batch.dart                   # Batch & BatchHistory data models
│   │   └── verification_result.dart     # Verification result types
│   ├── services/
│   │   ├── blockchain_service.dart      # Ethereum RPC + ABI calls
│   │   ├── supabase_service.dart        # Supabase DB fallback queries
│   │   └── scan_history_service.dart    # SharedPrefs scan history
│   ├── screens/
│   │   ├── main_screen.dart             # Bottom nav container
│   │   ├── verify_screen.dart           # Main verify + QR scan screen
│   │   ├── history_screen.dart          # Past scans list
│   │   └── about_screen.dart            # App info & how it works
│   └── widgets/
│       └── verification_result_card.dart # Verification result UI card
└── android/                             # Android build files
```

---

## 🔗 Smart Contract

| Field | Value |
|-------|-------|
| Network | Ethereum Sepolia Testnet |
| Address | `0x1E60556dE1625bD468eCe9e45a421aFa4bb1F73D` |
| Explorer | [View on Etherscan](https://sepolia.etherscan.io/address/0x1E60556dE1625bD468eCe9e45a421aFa4bb1F73D) |

---

## 🧪 Test Batch IDs

| Batch ID | Drug | Status |
|----------|------|--------|
| `BCH-0001` | DOLO-650 | Sold |
| `BCH-0010` | Imatinib Mesylate | Sold |

---

## 📄 License

MIT License · Part of [MediTrustChain](https://github.com/eng22cs0121/FINAL-YEAR-PROJECT) · Final Year B.E. CSE 2026

