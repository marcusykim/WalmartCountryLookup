# Walmart Country Lookup

An iOS app written in **Swift 6** using **UIKit**. It fetches a list of countries, lets users live‑search, and includes a “pull for rollback deal” feature. If the network request fails, the app falls back to a bundled JSON file. The project follows an **MVVM** architecture with protocol‑driven networking.

---

## Screen Recordings (GIFs)

<!-- Add your GIF links or files here -->
![Demo Part 1](gif1.gif)
![Demo Part 2](gif2.gif)

---

## Overview

* **Language & UI**: Swift 6, programmatic UIKit.
* **Architecture**: Model‑View‑ViewModel (MVVM) with protocol‑oriented networking.
* **Concurrency**: `async/await` and `@MainActor` for main‑thread safety.
* **Resilience**:
  * **Retry + Back‑off** on network errors.
  * **Bundle Fallback** if the API fails.
  * **Diffable Data Source** for smooth table updates.
  * **Debounced Search** while typing.
  * **Pull‑to‑Deal** shows a random country with a fun promo.
  * **Configurable Info.plist** values (URL, timeout, retry settings).
  * **Error Alert** appears when the network request fails—try changing the URL in `Info.plist` to see it.

---

## Project Structure
```
WalmartCountryLookup/
├─ README.md
├─ Resources/
│  └─ countries.json
├─ WalmartCountryLookup/
│  ├─ AppDelegate.swift
│  ├─ SceneDelegate.swift
│  ├─ Info.plist
│  ├─ Assets.xcassets/
│  │  ├─ AppIcon.appiconset/
│  │  └─ AccentColor.colorset/
│  ├─ Models/
│  │  ├─ Country.swift
│  │  └─ DealMessages.swift
│  ├─ Services/
│  │  ├─ Config.swift
│  │  └─ NetworkService.swift
│  ├─ ViewModels/
│  │  └─ CountriesViewModel.swift
│  └─ Views/
│     ├─ CountriesViewController.swift
│     └─ CountryTableViewCell.swift
└─ WalmartCountryLookup.xcodeproj/
   └─ (Xcode project files)
```

---

## Code Highlights & Justifications

### 1. Model: `Country.swift`
* Conforms to `Codable` and `Hashable` for easy decoding and diffable‑data‑source support.
* Default values (“N/A”) keep the UI consistent when data is missing.
* Accepts either two‑ or three‑letter ISO codes to future‑proof the model.

### 2. Networking: `NetworkService.swift`
* Reads the API URL, timeout, retry count, and delay from **Info.plist** via `Config`.
* Uses `async/await` for clean asynchronous code.
* Retries failed requests with exponential back‑off and throws custom `NetworkError` values.

### 3. ViewModel: `CountriesViewModel.swift`
* Runs on the main actor to keep UI updates safe.
* Loads data from the network and falls back to the bundled JSON file when necessary.
* Filters results with a 300 ms debounce.
* Exposes a `state` enum so the controller can show activity indicators or error alerts.

### 4. View: Key Snippets
* `CountriesViewController` sets up a `UITableViewDiffableDataSource` and applies snapshots whenever the filtered list changes.
* `bindViewModel()` reacts to `.loading`, `.loaded`, and `.error` states—presenting an alert when an error occurs.
* Pull‑to‑refresh triggers a random “deal of the day” alert and offers a “Show All” button to reset the list.

---

## Installation & Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/WalmartCountryLookup.git
   cd WalmartCountryLookup
2. **Open in Xcode**

open WalmartCountryLookup.xcodeproj
3. **Run the app**

*Choose the WalmartCountryLookup scheme.
*Select an iOS Simulator (15+) or a physical device.
*Press ⌘R.

4. **Experiment**

*Modify the CountriesURL in Info.plist to an invalid URL and run the app to see the error alert in action.
