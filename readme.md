## 🔄 Proton Drive Backup (macOS)

This script is designed to **synchronize local folders with Proton Drive** on macOS.

It will:

- Scan the folders you want to back up
- Compress them into `.tar.gz` archives
- Send the archives to your Proton Drive folder (via the official app)

---

### 🚧 Project status

> ⚠️ **This script is still under construction.**

Here’s the current roadmap:

- [x] Back up all folders defined in the config files and send them to the cloud folder
- [x] Skip the folders that haven't changed since the last backup
- [x] Add a log file for backup history
- [ ] Set up automated periodic backups

---

### 🛠️ Requirements

- [`jq`](https://jqlang.org/download/) – used for parsing and editing JSON files
