# Contributing to CleanMac

Thank you for your interest in contributing to CleanMac! We welcome contributions from developers of all skill levels. By contributing to this project, you help make a modern, private, and free macOS system utility accessible to everyone.

---

## 🛠️ Getting Started

### Prerequisites
* A Mac running macOS 13 or newer.
* Swift 5.9 or newer (installed via Xcode or Command Line Tools).

### Building from Source
To compile the CleanMac binary locally:
1. Clone your fork of the repository:
   ```bash
   git clone https://github.com/YOUR-USERNAME/cleanmac.git
   cd cleanmac/CleanMac
   ```
2. Build the project:
   ```bash
   swift build
   ```
3. Run the executable in the background:
   ```bash
   ./.build/debug/CleanMac &
   ```

---

## 🤝 How to Contribute

### 1. Reporting Bugs
* Check the existing issues to ensure the bug hasn't been reported yet.
* Open a new issue using the **Bug Report Template** and provide as much detail as possible (macOS version, reproduction steps, console output).

### 2. Suggesting Features
* Open a feature request issue explaining the feature and why it would be useful.
* Provide design or implementation thoughts if you have them!

### 3. Submitting Pull Requests
1. Fork the repository and create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. Make your changes and write clean, readable Swift code.
3. Verify that the app builds without errors.
4. Commit your changes with a clear message:
   ```bash
   git commit -m "Add feature to schedule background scans"
   ```
5. Push to your branch and open a Pull Request using our **PR Template**.

---

## 📜 Code of Conduct
Please be respectful and constructive in all interactions within this community. We aim to foster a welcoming and supportive environment.
