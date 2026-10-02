macOS IT Operations Toolkit v3.0 - Advanced Native Mac Edition
===============================================================

PURPOSE
An all-in-one native macOS IT support, diagnostics, reporting, repair and asset-information console.

NO EXTRA SOFTWARE REQUIRED
- No PowerShell
- No Homebrew
- No Python
- No third-party runtime
- The toolkit itself does not need to download software

HOW TO OPEN
1. Extract the ZIP.
2. Open the macos-it-operations-toolkit folder.
3. Double-click: Start MacOps Toolkit.command
4. If macOS blocks it: right-click the file > Open > Open.

MAIN CAPABILITIES
- System dashboard
- Full diagnostic report
- Hardware information
- Advanced battery health and capacity information
- Storage analysis and large-file discovery
- CPU, memory and process monitoring
- Network and internet diagnostic wizard
- DNS, ping, traceroute and active connection tools
- Wi-Fi information
- Security status: FileVault, firewall, SIP, Gatekeeper, remote login and listening ports
- Application inventory and startup items
- Users and connected devices
- Printers, Bluetooth and audio information
- macOS update check
- Safe repair centre
- Safe cleanup scan
- System logs, crashes and shutdown analysis
- Support case creation
- Asset inventory
- HTML and text reports
- Quick actions and tool search

BATTERY INFORMATION
Where macOS exposes the relevant values, the Battery module reports:
- Charge remaining percentage
- Current capacity (mAh)
- Full charge capacity (mAh)
- Design capacity (mAh)
- Capacity used since full charge
- Battery health / maximum capacity
- Estimated capacity loss
- Cycle count
- Condition
- Charging status
- Power source
- Time remaining
- Voltage
- Amperage
- Temperature

Apple changes which battery fields are exposed across Mac models and macOS releases. The toolkit shows "Not available" rather than guessing missing data.

SAFETY
Read-only diagnostics are the default. Operations that can modify system state are placed in the Safe Repair Centre and request confirmation. macOS may ask for an administrator password for privileged actions.

OUTPUT FOLDERS
reports   - generated diagnostic/HTML reports
logs      - toolkit activity logs
cases     - support case records
inventory - asset inventory records
