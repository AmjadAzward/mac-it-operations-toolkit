# macOS IT Operations Toolkit v3.1

A native shell-based **Advanced Technician Console** for macOS IT support, helpdesk troubleshooting, endpoint diagnostics, battery health analysis, network troubleshooting, security checks, hardware inventory, reporting, and technician case documentation.

The project remains fully **native to macOS** and uses built-in macOS utilities wherever possible. No Homebrew, PowerShell, Python, web server, database, service, or third-party runtime installation is required for the core toolkit.

---

## Latest Release

### v3.1 - Battery Diagnostics & Parsing Fixes

**Current Version: v3.1**

Latest improvements include:

- Fixed battery percentage parsing
- Fixed incorrect nested dictionary output for battery fields
- Improved Design Capacity detection
- Improved Full Charge Capacity detection
- Improved Current Capacity handling
- Added estimated current-capacity fallback when macOS does not expose a direct value
- Improved Battery Health calculation
- Added Estimated Capacity Loss
- Improved Apple Silicon battery parsing
- Improved Intel Mac battery compatibility
- Added multiple native battery information fallbacks
- Improved battery condition and service-warning detection
- Retained all v3.0 diagnostics, reporting, security, and case-management functionality

---

## Version History

| Version | Release Focus | Key Additions |
|---|---|---|
| **v3.1** | **Latest - Battery Diagnostics Fixes** | Improved charge %, capacity parsing, design capacity, health %, wear %, Apple Silicon compatibility |
| v3.0 | Advanced Native Technician Console | System dashboard, full diagnostics, battery tools, storage, network, security, reports, logs, support cases |
| v2.0 | Native macOS Edition | Removed PowerShell/Homebrew dependency and converted toolkit to native macOS shell tools |
| v1.2 | PowerShell Installer Improvements | Removed Homebrew requirement and added direct PowerShell installer support |
| v1.1 | macOS Launcher Fix | Added `.command` launcher and fixed PowerShell script issues |
| v1.0 | Initial Release | Core macOS IT operations and troubleshooting functionality |

---

## Features

### System Dashboard

- Mac model
- Serial number
- macOS version and build
- Apple Silicon / Intel detection
- CPU information
- Memory information
- System uptime
- Disk usage
- Network status
- Battery status
- FileVault status
- Firewall status
- Gatekeeper status
- SIP status

---

### Performance

- CPU usage
- Memory usage
- System uptime
- Disk usage
- Top CPU processes
- Top memory processes
- Running-process visibility
- Basic performance analysis

---

### Battery Health

- Current charge percentage
- Current battery capacity
- Full charge capacity
- Design capacity
- Used capacity
- Estimated current capacity when required
- Battery health percentage
- Estimated capacity loss
- Cycle count
- Battery condition
- Charging state
- Power source
- Time remaining where available
- Voltage
- Amperage
- Battery temperature where available
- Service Recommended detection

Battery information is collected from available native macOS sources and validated before display.

If macOS does not expose a reliable value, the toolkit reports:

```text
Not available
```

instead of generating an incorrect value.

---

### Storage

- Total disk capacity
- Used disk space
- Free disk space
- Home-directory usage
- Large-file discovery
- Downloads folder analysis
- Desktop usage
- Documents usage
- Cache inspection
- Temporary-file inspection
- Trash usage
- Storage troubleshooting

---

### Network

- Active network adapter information
- IPv4 information
- Default gateway
- DNS configuration
- Internet connectivity
- DNS resolution
- Ping testing
- Traceroute
- Network interface inventory
- Routing table
- Active network connections
- Listening-port inventory
- Wi-Fi interface information
- Current SSID
- Local network information

---

### Internet Diagnostics

The toolkit can perform a basic connectivity workflow including:

- Network interface check
- IP-address validation
- Gateway reachability
- DNS-resolution test
- Internet reachability
- Basic latency testing
- Connectivity troubleshooting guidance

---

### Wi-Fi Diagnostics

- Current Wi-Fi interface
- SSID
- Wi-Fi connection details
- Interface information
- Signal information where exposed by macOS
- Network troubleshooting data

Some advanced wireless information may vary depending on macOS version and hardware.

---

### Security

- FileVault status
- macOS Firewall status
- System Integrity Protection status
- Gatekeeper status
- Remote Login status
- Remote-access checks
- Listening services
- Basic security configuration visibility
- User privilege information

---

### Hardware Inventory

- Mac model
- Model identifier
- Serial number
- Apple Silicon / Intel
- Processor information
- Memory
- Storage
- Graphics information where available
- Display information
- USB devices
- Thunderbolt devices
- Bluetooth information
- Audio devices
- Battery information

---

### Applications

- Installed application inventory
- Application search
- Application paths
- Basic version information
- Startup application inspection
- Login-item visibility
- LaunchAgents
- LaunchDaemons

---

### Users

- Current logged-in user
- Local user accounts
- Administrator accounts
- User home directories
- User shell information
- Basic login information

---

### Printer Support

- Installed printers
- Default printer
- Printer queue visibility
- Printing service status
- Queue troubleshooting
- Printing-system restart options

---

### Bluetooth

- Bluetooth hardware information
- Bluetooth controller information
- Connected-device visibility where available
- Basic Bluetooth troubleshooting information

---

### Audio

- Audio device information
- Input-device information
- Output-device information
- Basic audio-service troubleshooting

---

### macOS Update

- Current macOS version
- Available software updates
- Software Update status
- Native update checks
- Restart-related update information where available

---

### Troubleshooting & Remediation

- Flush DNS cache
- Restart Finder
- Restart Dock
- Restart selected macOS services
- Network troubleshooting
- DNS troubleshooting
- Printer troubleshooting
- Cache inspection
- Temporary-file inspection
- Basic system service recovery actions

Potentially disruptive actions require confirmation before execution.

---

### Crash & Log Analysis

- Recent crash reports
- Application crashes
- System error information
- Recent system log review
- Shutdown / restart analysis
- Common troubleshooting events
- Basic error summaries

---

### Support Case Management

Create and maintain basic technician support records including:

- Case ID
- Date
- Technician
- User
- Device
- Serial number
- Reported issue
- Diagnostic information
- Actions taken
- Resolution
- Case status

Suggested statuses include:

```text
Open
In Progress
Waiting for User
Escalated
Resolved
Closed
```

---

### Asset Inventory

The toolkit can collect asset information including:

- Computer name
- Serial number
- Mac model
- macOS version
- Processor type
- Memory
- Storage
- Username
- IP address
- Security status
- Battery information

---

### Reporting

- Full diagnostic text report
- HTML IT support report
- Device information
- Hardware details
- Battery health
- Storage information
- Network information
- Security status
- Diagnostic findings
- Technician notes
- Support information

Reports can be used for:

- Helpdesk documentation
- Internal IT support
- Asset records
- Escalations
- Troubleshooting evidence
- Support-case documentation

---

## Quick Start

Run:

```text
Start MacOps Toolkit.command
```

The easiest method is to double-click the launcher.

If macOS blocks the file because it was downloaded:

1. Right-click `Start MacOps Toolkit.command`
2. Select **Open**
3. Select **Open** again

Alternatively, run from Terminal:

```bash
chmod +x "Start MacOps Toolkit.command"
./"Start MacOps Toolkit.command"
```

---

## Main Menu

```text
SYSTEM & DIAGNOSTICS
 1. System Dashboard
 2. Full Mac Diagnostic
 3. Health Overview
 4. Hardware Information
 5. CPU & Memory
 6. Storage Analyzer
 7. Battery Health
 8. Performance Monitor

NETWORK
 9. Network Centre
10. Internet Diagnostic
11. Wi-Fi Diagnostics
12. DNS Tools
13. Port & Connection Tools

SECURITY
14. Security Centre
15. FileVault
16. Firewall
17. Gatekeeper / SIP
18. Remote Access / Sharing

SYSTEM MANAGEMENT
19. Applications
20. Startup Items
21. Processes
22. Users
23. Connected Devices
24. Printers
25. Bluetooth
26. Audio
27. macOS Updates

SUPPORT & REMEDIATION
28. Safe Repair Centre
29. Safe Cleanup Centre
30. Cache / Temporary Files

LOGS & TROUBLESHOOTING
31. System Logs
32. Crash Analyzer
33. Shutdown Analyzer

REPORTING & CASE MANAGEMENT
34. Support Cases
35. Asset Inventory
36. Generate IT Report
37. Export Diagnostics

TOOLS
38. Quick Actions
39. Search Tools

 0. Exit
```

---

## Safety

- Diagnostic functions are read-only wherever practical.
- System-changing actions require explicit confirmation.
- Administrator privileges are requested only when required.
- Passwords and credentials are not stored by the toolkit.
- FileVault recovery keys are not written to routine reports.
- Destructive maintenance actions are avoided by default.
- The toolkit does not disable macOS security controls automatically.
- Diagnostic reports may contain device names, usernames, IP addresses, hardware data, and installed-application information.

Do not publish production diagnostic output to public GitHub repositories.

---

## Requirements

- macOS
- Terminal
- Built-in macOS command-line utilities
- Administrator privileges for selected maintenance functions

No additional runtime is required for the core toolkit.

The toolkit does **not require**:

- Homebrew
- PowerShell
- Python
- Node.js
- Java
- Database software
- Web server
- Background service

---

## Compatibility

Designed for modern macOS systems including:

- Apple Silicon Macs
- Intel-based Macs

Some system fields may vary depending on:

- Mac model
- macOS version
- Apple Silicon vs Intel
- System permissions
- MDM policies
- Apple security restrictions
- Hardware capabilities

---

## Battery Data Notes

Battery information is one of the areas where macOS exposes different values on different hardware generations.

The toolkit uses multiple native sources where appropriate, including available information from:

- `pmset`
- `ioreg`
- `system_profiler`

Battery values are validated before being displayed.

Battery Health is calculated only when reliable Full Charge Capacity and Design Capacity values are available.

Example:

```text
Battery Health =
Full Charge Capacity / Design Capacity × 100
```

Estimated Capacity Loss is calculated as:

```text
100% - Battery Health
```

If Current Capacity is unavailable but macOS exposes a valid charge percentage and full-charge capacity, the toolkit may display an estimated current capacity and clearly label it as estimated.

---

## macOS Security Note

The toolkit is designed to work with macOS security controls rather than disabling them.

It does not automatically disable:

- Gatekeeper
- System Integrity Protection
- FileVault
- macOS Firewall
- Privacy protections

Where elevated access is required, standard macOS authorization mechanisms are used.

---

## Project Structure

Typical repository structure:

```text
mac-it-operations-toolkit/
├── README.md
├── Start MacOps Toolkit.command
├── macops.sh
├── modules/
├── reports/
├── logs/
├── cases/
└── .gitattributes
```

The exact structure may change as new modules are introduced.

---

## Git Line Ending Note

Because this project contains macOS shell scripts, `.command` and `.sh` files should use **LF** line endings.

Recommended `.gitattributes`:

```text
*.command text eol=lf
*.sh text eol=lf
*.zsh text eol=lf
*.bash text eol=lf
```

This helps prevent Windows Git clients from converting macOS scripts to CRLF line endings.

---

## Portfolio Skills Demonstrated

Shell scripting, macOS administration, IT support, helpdesk troubleshooting, endpoint diagnostics, networking, battery analysis, hardware inventory, endpoint security, process analysis, logging, incident documentation, reporting, Git, GitHub, modular scripting, and safe administrative automation.

---

## Roadmap

Planned improvements include:

- Advanced Mac health scoring
- Improved automatic issue detection
- Better troubleshooting recommendations
- Enhanced HTML dashboard
- Advanced Wi-Fi diagnostics
- Improved storage visualization
- More detailed Apple Silicon hardware support
- Automated support-case diagnostics
- Expanded asset inventory
- Better historical reports
- Improved network performance testing
- Additional safe repair tools

---

## GitHub Repository Description

Advanced native macOS IT Operations Toolkit for diagnostics, battery health, networking, security, hardware inventory, troubleshooting, reporting, and technician support workflows.

---

## Suggested GitHub Topics

```text
macos
mac
it-support
helpdesk
sysadmin
shell-script
bash
diagnostics
networking
battery-health
endpoint-management
troubleshooting
security
hardware-inventory
it-operations
```

---

## Disclaimer

Use only on systems you are authorized to support or administer.

Test modifying actions in a lab, test environment, or approved device before using them in production.

System commands and diagnostic values may behave differently depending on:

- macOS version
- Hardware model
- Apple Silicon vs Intel
- User permissions
- Security configuration
- MDM restrictions
- Organization policies

Always review diagnostic results before performing system changes.
