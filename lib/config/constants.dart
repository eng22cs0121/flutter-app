/// Application-wide constants for MediTrustChain Patient App.
/// These values mirror the web app's .env configuration.
class AppConstants {
  AppConstants._();

  // ── Supabase ────────────────────────────────────────────────────────
  static const String supabaseUrl = 'https://idmmiqypcjxejoyyhahj.supabase.co';

  /// Supabase anon key – safe to include in client apps (protected by RLS).
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkbW1pcXlwY2p4ZWpveXloYWhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NDg5MjcsImV4cCI6MjA4NDMyNDkyN30'
      '.iPFq3WbfJRV9AFPchQ-iTAS10rKf2MpfpZCOkUAqkcY';

  // ── Blockchain ──────────────────────────────────────────────────────
  static const String contractAddress =
      '0x1E60556dE1625bD468eCe9e45a421aFa4bb1F73D';

  /// Public Sepolia RPC – replace with a dedicated Alchemy/Infura key for production.
  static const String rpcUrl =
      'https://eth-sepolia.g.alchemy.com/v2/demo';

  static const String blockExplorerUrl = 'https://sepolia.etherscan.io';
  static const String chainName = 'Sepolia Testnet';
  static const int chainId = 11155111;

  // ── App metadata ────────────────────────────────────────────────────
  static const String appName = 'MediTrustChain';
  static const String appVersion = '1.0.0';
  static const String appTagline =
      'Verify medicine authenticity using blockchain technology';

  // ── Storage keys ────────────────────────────────────────────────────
  static const String scanHistoryKey = 'meditrust_scan_history';
  static const int maxHistoryEntries = 50;
}

/// Minimal ABI – only the three read-only functions the patient app needs.
const String kMediTrustAbi = '''
[
  {
    "inputs": [{"internalType": "string", "name": "batchCode", "type": "string"}],
    "name": "getBatchIdByCode",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "batchId", "type": "uint256"}],
    "name": "getBatchFull",
    "outputs": [
      {
        "components": [
          {"internalType": "uint256",  "name": "id",          "type": "uint256"},
          {"internalType": "string",   "name": "batchCode",   "type": "string"},
          {"internalType": "address",  "name": "manufacturer","type": "address"},
          {"internalType": "string",   "name": "drugName",    "type": "string"},
          {"internalType": "uint256",  "name": "quantity",    "type": "uint256"},
          {"internalType": "uint256",  "name": "mfgDate",     "type": "uint256"},
          {"internalType": "uint256",  "name": "expDate",     "type": "uint256"},
          {"internalType": "uint256",  "name": "createdAt",   "type": "uint256"},
          {"internalType": "bytes32",  "name": "dataHash",    "type": "bytes32"}
        ],
        "internalType": "struct MediTrustChainV2.BatchCore",
        "name": "",
        "type": "tuple"
      },
      {
        "components": [
          {"internalType": "uint8",    "name": "status",       "type": "uint8"},
          {"internalType": "uint256",  "name": "approvedAt",   "type": "uint256"},
          {"internalType": "bytes32",  "name": "approvalHash", "type": "bytes32"},
          {"internalType": "address",  "name": "currentHolder","type": "address"},
          {"internalType": "string",   "name": "lastLocation", "type": "string"},
          {"internalType": "bool",     "name": "isRecalled",   "type": "bool"},
          {"internalType": "uint256",  "name": "lastUpdated",  "type": "uint256"}
        ],
        "internalType": "struct MediTrustChainV2.BatchState",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "batchId",  "type": "uint256"},
      {"internalType": "bytes32", "name": "dataHash", "type": "bytes32"}
    ],
    "name": "verifyBatchWithHash",
    "outputs": [
      {"internalType": "bool",   "name": "isGenuine", "type": "bool"},
      {"internalType": "string", "name": "status",    "type": "string"}
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
''';
