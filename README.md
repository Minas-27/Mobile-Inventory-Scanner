<div align="center">

# Mobile Inventory Scanner

### Real-Time Warehouse Management for Odoo ERP

![Flutter](https://img.shields.io/badge/Flutter_3.x-%2302569B.svg?style=flat-square&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat-square&logo=dart&logoColor=white)
![Odoo](https://img.shields.io/badge/Odoo_15--18-%23714B67.svg?style=flat-square&logo=odoo&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android_%7C_iOS-green?style=flat-square)
![License](https://img.shields.io/badge/License-Proprietary-red?style=flat-square)

**A production-grade Flutter application that transforms any smartphone into an enterprise barcode scanner with live Odoo ERP synchronization — eliminating clipboard errors, data latency, and manual stock entry.**

</div>

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Application Flow](#application-flow)
- [Technical Architecture](#technical-architecture)
- [Project Structure](#project-structure)
- [Odoo Integration Details](#odoo-integration-details)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Compatibility](#compatibility)
- [Security](#security)

---

## Overview

Traditional warehouse inventory management relies on manual data entry — workers record stock counts on paper, then re-enter the data into ERP systems at a desktop terminal. This process introduces human error, duplicated effort, and dangerous gaps between physical reality and digital records (**phantom inventory**).

**Mobile Inventory Scanner** solves this by providing a direct, real-time bridge between the warehouse floor and Odoo ERP:

| Manual Process | With This App |
|---|---|
| Write barcode on clipboard | Point camera at barcode — instant recognition |
| Walk to desktop at end of shift | Adjust stock immediately on the floor |
| Type product ID manually | Automatic product lookup via Odoo JSON-RPC |
| Risk typos and lost notes | Machine-verified, zero-error data entry |
| Delayed ERP sync (hours/days) | Instant synchronization (< 1 second) |

---

## Key Features

### Barcode Scanning
- High-speed camera-based barcode detection using `mobile_scanner`
- Haptic feedback on successful scan for tactile confirmation
- Animated scan-line overlay with real-time visual guidance
- Flashlight toggle for low-light warehouse environments

### Odoo ERP Integration
- Direct JSON-RPC 2.0 communication — no middleware required
- Secure session-based authentication against any Odoo database
- Full `stock.quant` and `action_apply_inventory` support for stock adjustments
- Smart warehouse location resolution via `lot_stock_id` lookup — prevents duplicate entries
- Fetches product category (`categ_id`) and unit of measure (`uom_id`) for enriched data display

### Dashboard & Analytics
- Centralized dashboard with total scan count and unique item metrics
- Chronological scan history with relative timestamps
- Instant navigation to scanner with one tap

### User Experience
- Modern dark-themed UI with consistent design language across all screens
- Lucide icon system for clean, professional iconography
- Smooth slide-and-fade page transitions
- Contextual snackbar notifications with success/error visual indicators
- Logout confirmation dialog to prevent accidental session termination
- Animated splash screen with branded loading experience

### Stock Management
- Real-time product detail view with barcode, category, and unit of measure
- Intuitive quantity adjustment with increment/decrement controls
- Direct "Sync to Odoo" action that commits changes to `stock.quant` immediately
- Current stock display with live data from Odoo backend

---

## Application Flow

```
Splash Screen ──▶ Login Screen ──▶ Dashboard ──▶ Scanner ──▶ Product Detail
     │                │                │             │              │
  Animated         Odoo Auth       Stats &        Camera         Adjust Qty
  branding        (JSON-RPC)     Scan History    Barcode       & Sync to Odoo
                                                Detection
```

| Screen | Purpose |
|---|---|
| **Splash** | Branded launch animation with version label |
| **Login** | Connects to Odoo instance with URL, database, username, and password |
| **Dashboard** | Displays scan statistics, recent history, and primary navigation |
| **Scanner** | Camera-based barcode detection with overlay and flashlight control |
| **Product Detail** | Displays product info, current stock, and provides quantity adjustment with Odoo sync |

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  SplashScreen  LoginScreen  DashboardScreen  ScannerScreen  │
│                          ProductDetailScreen                 │
├─────────────────────────────────────────────────────────────┤
│                     State Management                         │
│                  InventoryProvider (ChangeNotifier)           │
│           ┌── currentProduct  ┌── scanHistory                │
│           ├── isLoading       └── totalScans                 │
│           └── errorMessage                                   │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                           │
│            OdooService (abstract interface)                   │
│          ┌──────────┴──────────────┐                         │
│    OdooApiService            MockOdooService                 │
│   (Production - JSON-RPC)    (Development/Testing)           │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                                 │
│               Product Model (id, name, barcode,              │
│           qtyAvailable, category, uom, scannedAt)            │
├─────────────────────────────────────────────────────────────┤
│                    External                                   │
│               Odoo ERP (JSON-RPC 2.0 over HTTP)              │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart |
| **State Management** | Provider (ChangeNotifier) |
| **Barcode Scanning** | mobile_scanner 7.x |
| **HTTP Client** | dart:http |
| **Typography** | Google Fonts (Inter) |
| **Iconography** | Lucide Icons |
| **Backend Protocol** | JSON-RPC 2.0 |
| **Target ERP** | Odoo 15, 16, 17, 18 |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point & root widget
├── models/
│   └── product.dart                   # Product data model with JSON serialization
├── providers/
│   └── inventory_provider.dart        # State management (scan history, stock ops)
├── screens/
│   ├── splash_screen.dart             # Animated branded launch screen
│   ├── login_screen.dart              # Odoo authentication with form validation
│   ├── dashboard_screen.dart          # Stats, scan history, primary navigation
│   ├── scanner_screen.dart            # Camera barcode scanner with overlay
│   └── product_detail_screen.dart     # Product info & quantity adjustment
├── services/
│   ├── odoo_service.dart              # Abstract service interface + mock
│   └── odoo_api_service.dart          # Production Odoo JSON-RPC implementation
└── theme/
    └── app_theme.dart                 # Centralized theme, colors & typography
```

---

## Odoo Integration Details

The application communicates with Odoo exclusively through **JSON-RPC 2.0** calls, targeting three core models:

### Authentication
- **Endpoint:** `/web/session/authenticate`
- Establishes a session cookie for all subsequent API calls

### Product Lookup
- **Model:** `product.product`
- **Method:** `search_read`
- **Fields:** `id`, `name`, `barcode`, `qty_available`, `categ_id`, `uom_id`
- Searches by exact barcode match

### Stock Adjustment
- **Model:** `stock.warehouse` — resolves the primary `lot_stock_id` for the warehouse
- **Model:** `stock.quant` — searches or creates stock entries at the resolved location
- **Method:** `action_apply_inventory` — commits the quantity change to the ERP ledger

> **Note:** The smart warehouse resolution prevents a common integration pitfall where stock adjustments are applied to an incorrect or default location, causing phantom inventory records.

---

## Getting Started

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | 3.x or later |
| Dart SDK | 3.11+ |
| Android Studio / Xcode | Latest stable |
| Odoo Instance | 15, 16, 17, or 18 with Inventory module enabled |
| Physical Device | Required for camera-based barcode scanning |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Minas-27/Mobile-Inventory-Scanner.git

# 2. Navigate to the project directory
cd Mobile-Inventory-Scanner

# 3. Install dependencies
flutter pub get

# 4. Run on a connected device
flutter run
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS with Xcode)
flutter build ios --release
```

---

## Configuration

### Connecting to Your Odoo Instance

On the login screen, provide:

| Field | Example | Description |
|---|---|---|
| **Odoo URL** | `http://192.168.0.113:8069` | Full URL of the Odoo server |
| **Database** | `odoo_production` | Name of the Odoo PostgreSQL database |
| **Username** | `admin` | Odoo user login |
| **Password** | `••••••` | Odoo user password |

### Network Configuration (Android)

For local HTTP (non-HTTPS) Odoo instances, cleartext traffic is already enabled in the Android manifest. No additional configuration is required for local network deployment.

---

## Compatibility

| Platform | Status |
|---|---|
| Android 5.0+ (API 21+) | Fully supported |
| iOS 12+ | Fully supported |
| Odoo 15 | Tested and verified |
| Odoo 16 | Tested and verified |
| Odoo 17 | Tested and verified |
| Odoo 18 | Tested and verified |

---

## Security

- **Session-based authentication** — credentials are transmitted only during login and are not persisted on-device
- **No hardcoded API keys** — all connection details are provided at runtime by the operator
- **Cleartext traffic** is limited to local network deployments; HTTPS is fully supported for production Odoo instances
- **No third-party analytics or tracking** — the app communicates exclusively with the configured Odoo server

---

<div align="center">

**Mobile Inventory Scanner** — Built for speed, accuracy, and seamless Odoo integration.

*Version 1.0.0*

</div>
