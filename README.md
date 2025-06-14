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

