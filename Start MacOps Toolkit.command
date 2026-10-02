#!/bin/bash
# macOS IT Operations Toolkit v3.1 - Native Advanced Edition
# Uses built-in macOS utilities only. No PowerShell, Homebrew, Python, or third-party runtime.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPORTS="$SCRIPT_DIR/reports"; LOGS="$SCRIPT_DIR/logs"; CASES="$SCRIPT_DIR/cases"; INVENTORY="$SCRIPT_DIR/inventory"
mkdir -p "$REPORTS" "$LOGS" "$CASES" "$INVENTORY"
LOGFILE="$LOGS/macops-$(date '+%Y-%m-%d').log"

log_msg(){ printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOGFILE"; }
pause(){ printf '\nPress ENTER to return...'; read _; }
line(){ printf '%s\n' '======================================================================'; }
val_or_na(){ [ -n "$1" ] && printf '%s' "$1" || printf 'Not available on this Mac'; }
computer_name(){ scutil --get ComputerName 2>/dev/null || hostname; }
serial_number(){ system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Serial Number/{print $2; exit}'; }
mac_model(){ system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/{print $2; exit}'; }
mac_chip(){ system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip:|Processor Name:/{print $2; exit}'; }
active_iface(){ route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'; }
primary_ip(){ local i; i=$(active_iface); [ -n "$i" ] && ipconfig getifaddr "$i" 2>/dev/null; }

header(){
  clear; line
  printf '              macOS IT OPERATIONS TOOLKIT v3.1\n'
  printf '          ADVANCED NATIVE MAC EDITION - OFFLINE READY\n'; line
  printf ' Computer : %s\n' "$(computer_name)"
  printf ' User     : %s\n' "${USER:-$(whoami)}"
  printf ' macOS    : %s (%s)\n' "$(sw_vers -productVersion 2>/dev/null)" "$(sw_vers -buildVersion 2>/dev/null)"
  printf ' Model    : %s\n' "$(mac_model)"
  printf ' IP       : %s\n' "$(val_or_na "$(primary_ip)")"
  line; printf '\n'
}
run_title(){ header; printf '%s\n' "$1"; printf '%s\n\n' '----------------------------------------------------------------------'; log_msg "$1"; }
confirm(){ printf '%s [y/N]: ' "$1"; read ans; case "$ans" in y|Y|yes|YES) return 0;; *) return 1;; esac; }

battery_data(){
  BAT_PLIST="$(ioreg -rn AppleSmartBattery -r -a 2>/dev/null || true)"
  BAT_TEXT="$(ioreg -rn AppleSmartBattery -r -l 2>/dev/null || true)"

  # Read an exact key path from ioreg's plist output. Apple moves some values
  # between top-level and nested BatteryData dictionaries across macOS/models.
  plist_raw(){
    local path="$1" out
    [ -n "$BAT_PLIST" ] || return 1
    out=$(printf '%s' "$BAT_PLIST" | plutil -extract "$path" raw -o - - 2>/dev/null) || return 1
    printf '%s' "$out"
  }
  first_numeric_plist(){
    local path out
    for path in "$@"; do
      out=$(plist_raw "$path" 2>/dev/null || true)
      case "$out" in ''|*[!0-9-]*) ;; *) printf '%s' "$out"; return 0;; esac
    done
    return 1
  }
  first_text_plist(){
    local path out
    for path in "$@"; do
      out=$(plist_raw "$path" 2>/dev/null || true)
      [ -n "$out" ] && { printf '%s' "$out"; return 0; }
    done
    return 1
  }

  # Exact plist paths first; nested BatteryData fallbacks are intentional.
  B_CUR=$(first_numeric_plist '0.CurrentCapacity' '0.AppleRawCurrentCapacity' '0.BatteryData.CurrentCapacity' || true)
  B_MAX=$(first_numeric_plist '0.MaxCapacity' '0.AppleRawMaxCapacity' '0.BatteryData.MaxCapacity' '0.BatteryData.FccComp1' '0.BatteryData.FccComp2' || true)
  B_DES=$(first_numeric_plist '0.DesignCapacity' '0.AppleRawMaxCapacity' '0.BatteryData.DesignCapacity' || true)
  B_CYCLE=$(first_numeric_plist '0.CycleCount' '0.BatteryData.CycleCount' || true)
  B_VOLT=$(first_numeric_plist '0.Voltage' '0.BatteryData.Voltage' || true)
  B_AMP=$(first_numeric_plist '0.Amperage' '0.InstantAmperage' '0.BatteryData.Amperage' '0.BatteryData.Current' || true)
  B_TEMP_RAW=$(first_numeric_plist '0.Temperature' '0.BatteryData.Temperature' || true)
  B_CHARGING=$(first_text_plist '0.IsCharging' || true)

  PM_ALL="$(pmset -g batt 2>/dev/null || true)"
  PM_BATT=$(printf '%s\n' "$PM_ALL" | tail -1)
  # Extract the complete percentage token (e.g. 74%), avoiding greedy sed capture.
  B_PM_PCT=$(printf '%s\n' "$PM_BATT" | grep -Eo '[0-9]{1,3}%' | head -1 | tr -d '%' || true)
  B_POWER=$(printf '%s\n' "$PM_ALL" | head -1 | sed "s/Now drawing from '//; s/'.*//")
  B_TIME=$(printf '%s\n' "$PM_BATT" | sed -n 's/.*; \([^;]*remaining\).*/\1/p' | xargs)

  POWER_PROFILE="$(system_profiler SPPowerDataType 2>/dev/null || true)"
  B_COND=$(printf '%s\n' "$POWER_PROFILE" | awk -F': ' '/Condition:/{print $2; exit}')
  B_SYS_MAX=$(printf '%s\n' "$POWER_PROFILE" | awk -F': ' '/Maximum Capacity:/{print $2; exit}')

  # Normalize booleans for display.
  case "$B_CHARGING" in 1|true|TRUE|Yes|YES) B_CHARGING='Yes';; 0|false|FALSE|No|NO) B_CHARGING='No';; esac

  # Sanity checks. Do not display dictionaries/garbage as numbers.
  for v in B_CUR B_MAX B_DES B_CYCLE B_VOLT B_AMP B_TEMP_RAW B_PM_PCT; do
    eval "x=\${$v}"
    case "$x" in ''|*[!0-9-]*) eval "$v=''";; esac
  done

  # Some Apple Silicon models report CurrentCapacity as 0 or omit it while
  # pmset still reports the real state of charge. Derive a display estimate
  # only when a valid charge percentage and full-charge capacity are known.
  B_CUR_ESTIMATED='No'
  if { [ -z "$B_CUR" ] || [ "$B_CUR" -eq 0 ] 2>/dev/null; } && [ -n "$B_PM_PCT" ] && [ "$B_PM_PCT" -gt 0 ] 2>/dev/null && [ -n "$B_MAX" ] && [ "$B_MAX" -gt 0 ] 2>/dev/null; then
    B_CUR=$(( B_MAX * B_PM_PCT / 100 ))
    B_CUR_ESTIMATED='Yes'
  fi
}

battery_report(){
  run_title 'BATTERY HEALTH & CAPACITY'; battery_data
  printf 'BATTERY STATUS\n\n'
  charge_pct="$B_PM_PCT"
  if [ -z "$charge_pct" ] && [ -n "$B_CUR" ] && [ -n "$B_MAX" ] && [ "$B_MAX" -gt 0 ] 2>/dev/null; then charge_pct=$(( B_CUR * 100 / B_MAX )); fi

  health_pct=''
  if [ -n "$B_MAX" ] && [ -n "$B_DES" ] && [ "$B_DES" -gt 0 ] 2>/dev/null; then
    health_pct=$(awk -v m="$B_MAX" -v d="$B_DES" 'BEGIN{printf "%.1f",(m/d)*100}')
  elif printf '%s' "$B_SYS_MAX" | grep -Eq '^[0-9]{1,3}%$'; then
    health_pct=$(printf '%s' "$B_SYS_MAX" | tr -d '%')
  fi

  used=''; loss=''
  if [ -n "$B_CUR" ] && [ -n "$B_MAX" ] && [ "$B_MAX" -ge "$B_CUR" ] 2>/dev/null; then used=$(( B_MAX - B_CUR )); fi
  if [ -n "$health_pct" ]; then loss=$(awk -v h="$health_pct" 'BEGIN{v=100-h; if(v<0)v=0; printf "%.1f",v}'); fi

  temp=''
  if [ -n "$B_TEMP_RAW" ] && [ "$B_TEMP_RAW" -gt 0 ] 2>/dev/null; then
    # Apple commonly reports temperature in centi-Kelvin/centi-Celsius style
    # values around 3000 for ~30 C on AppleSmartBattery.
    temp=$(awk -v t="$B_TEMP_RAW" 'BEGIN{printf "%.1f °C", t/100}')
  fi

  current_label='Current Capacity:'
  [ "$B_CUR_ESTIMATED" = 'Yes' ] && current_label='Current Capacity (est.):'

  printf '%-30s %s\n' 'Charge Remaining:' "$( [ -n "$charge_pct" ] && echo "$charge_pct%" || echo 'Not available')"
  printf '%-30s %s\n' "$current_label" "$( [ -n "$B_CUR" ] && echo "$B_CUR mAh" || echo 'Not available')"
  printf '%-30s %s\n' 'Full Charge Capacity:' "$( [ -n "$B_MAX" ] && echo "$B_MAX mAh" || echo 'Not available')"
  printf '%-30s %s\n' 'Design Capacity:' "$( [ -n "$B_DES" ] && echo "$B_DES mAh" || echo 'Not available')"
  printf '%-30s %s\n' 'Used Since Full Charge:' "$( [ -n "$used" ] && echo "$used mAh" || echo 'Not available')"
  printf '%-30s %s\n' 'Battery Health:' "$( [ -n "$health_pct" ] && echo "$health_pct%" || echo 'Not available')"
  printf '%-30s %s\n' 'Estimated Capacity Loss:' "$( [ -n "$loss" ] && echo "$loss%" || echo 'Not available')"
  printf '%-30s %s\n' 'Cycle Count:' "${B_CYCLE:-Not available}"
  printf '%-30s %s\n' 'Condition:' "${B_COND:-Not available}"
  printf '%-30s %s\n' 'Charging:' "${B_CHARGING:-Not available}"
  printf '%-30s %s\n' 'Power Source:' "${B_POWER:-Not available}"
  printf '%-30s %s\n' 'Time Remaining:' "${B_TIME:-Not available}"
  printf '%-30s %s\n' 'Voltage:' "$( [ -n "$B_VOLT" ] && echo "$B_VOLT mV" || echo 'Not available')"
  printf '%-30s %s\n' 'Amperage:' "$( [ -n "$B_AMP" ] && echo "$B_AMP mA" || echo 'Not available')"
  printf '%-30s %s\n' 'Temperature:' "${temp:-Not available}"

  printf '\nASSESSMENT\n'
  if [ -n "$health_pct" ]; then
    health_whole=$(awk -v h="$health_pct" 'BEGIN{printf "%d",h}')
    if [ "$health_whole" -lt 70 ]; then echo 'CRITICAL: Maximum capacity is below 70% of design capacity.'
    elif [ "$health_whole" -lt 80 ]; then echo 'WARNING: Maximum capacity is below 80% of design capacity.'
    else echo 'PASS: Maximum capacity is at or above 80% of design capacity.'; fi
  else
    echo 'INFO: Health percentage is unavailable because macOS did not expose enough reliable capacity data.'
  fi
  case "$B_COND" in *Service*|*Replace*) echo "WARNING: macOS reports battery condition: $B_COND";; Normal) echo 'PASS: macOS reports battery condition as Normal.';; esac
  [ "$B_CUR_ESTIMATED" = 'Yes' ] && echo 'INFO: Current capacity is estimated from charge % × full-charge capacity because macOS returned 0 for CurrentCapacity.'
}

system_dashboard(){
  run_title 'SYSTEM DASHBOARD'
  mem=$(sysctl -n hw.memsize 2>/dev/null); memgb=$(awk -v b="${mem:-0}" 'BEGIN{printf "%.1f GB",b/1073741824}')
  disk=$(df -h / | awk 'NR==2{print $3" used / "$2" total ("$5")"}')
  fw=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | sed 's/.*State = //')
  fv=$(fdesetup status 2>/dev/null); sip=$(csrutil status 2>/dev/null); gk=$(spctl --status 2>/dev/null)
  battery_data
  printf '%-24s %s\n' 'Computer:' "$(computer_name)"
  printf '%-24s %s\n' 'Serial Number:' "$(serial_number)"
  printf '%-24s %s\n' 'Chip/Processor:' "$(mac_chip)"
  printf '%-24s %s\n' 'Memory:' "$memgb"
  printf '%-24s %s\n' 'Root Storage:' "$disk"
  printf '%-24s %s\n' 'Uptime:' "$(uptime | sed 's/.*up //; s/, [0-9][0-9]* users.*//; s/, load averages.*//')"
  printf '%-24s %s\n' 'Network Interface:' "$(val_or_na "$(active_iface)")"
  printf '%-24s %s\n' 'IP Address:' "$(val_or_na "$(primary_ip)")"
  printf '%-24s %s\n' 'Battery Charge:' "${B_PM_PCT:+$B_PM_PCT%}"
  printf '%-24s %s\n' 'Battery Condition:' "${B_COND:-Not available}"
  printf '%-24s %s\n' 'FileVault:' "$fv"
  printf '%-24s %s\n' 'Firewall:' "${fw:-Not available}"
  printf '%-24s %s\n' 'SIP:' "$sip"
  printf '%-24s %s\n' 'Gatekeeper:' "$gk"
}

full_diagnostic_to_file(){
  out="$REPORTS/full-diagnostic-$(date '+%Y%m%d-%H%M%S').txt"
  {
    echo 'macOS IT Operations Toolkit v3.1 - Full Diagnostic'; date; echo
    echo '=== SYSTEM ==='; sw_vers; uptime; echo
    echo '=== HARDWARE ==='; system_profiler SPHardwareDataType 2>/dev/null; echo
    echo '=== POWER/BATTERY ==='; pmset -g batt 2>/dev/null; system_profiler SPPowerDataType 2>/dev/null; echo
    echo '=== STORAGE ==='; df -h; diskutil info / 2>/dev/null; echo
    echo '=== MEMORY ==='; memory_pressure 2>/dev/null || vm_stat; echo
    echo '=== TOP PROCESSES ==='; ps -Ao pid,user,%cpu,%mem,etime,comm -r | head -25; echo
    echo '=== NETWORK ==='; scutil --nwi 2>/dev/null; route -n get default 2>/dev/null; echo; scutil --dns 2>/dev/null | head -160; echo
    echo '=== SECURITY ==='; fdesetup status 2>/dev/null; csrutil status 2>/dev/null; spctl --status 2>/dev/null; /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null; echo
    echo '=== LOGIN ITEMS ==='; osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || true; echo
    echo '=== RECENT CRASH REPORTS ==='; find "$HOME/Library/Logs/DiagnosticReports" /Library/Logs/DiagnosticReports -type f -mtime -2 2>/dev/null | tail -30; echo
  } > "$out"
  run_title 'FULL DIAGNOSTIC COMPLETE'; echo "Report saved to:"; echo "$out"; printf '\nPreview:\n'; sed -n '1,90p' "$out"
}

hardware_info(){ run_title 'HARDWARE INFORMATION'; system_profiler SPHardwareDataType SPDisplaysDataType 2>/dev/null; }
storage_analyzer(){
  run_title 'STORAGE ANALYZER'; df -h /; echo; diskutil info / 2>/dev/null | egrep 'Volume Name|Mounted|File System|Disk Size|Container Total Space|Container Free Space|Solid State|SMART Status' || true
  echo; echo 'Largest folders in your Home directory (may take a moment):'; du -sh "$HOME"/* 2>/dev/null | sort -h | tail -15
  echo; echo 'Files larger than 1 GB in Home (top 20):'; find "$HOME" -type f -size +1G -print 2>/dev/null | head -20
}
process_health(){ run_title 'PERFORMANCE MONITOR'; echo 'Top CPU processes:'; ps -Ao pid,user,%cpu,%mem,etime,comm -r | head -18; echo; echo 'Top memory processes:'; ps -Ao pid,user,%cpu,%mem,etime,comm -m | head -18; echo; uptime; echo; memory_pressure 2>/dev/null | tail -15 || vm_stat; }

network_center(){
 while true; do header; echo 'NETWORK & INTERNET CENTRE'; echo; printf ' 1. Network summary\n 2. Interfaces and IP addresses\n 3. Route and DNS\n 4. Internet diagnostic wizard\n 5. Ping target\n 6. Traceroute target\n 7. DNS lookup\n 8. Active/listening connections\n 9. Flush DNS cache [Admin]\n10. Renew DHCP [Admin]\n 0. Back\n\nSelect: '; read c
 case "$c" in
 1) run_title 'NETWORK SUMMARY'; echo "Active interface: $(active_iface)"; echo "IP: $(primary_ip)"; route -n get default 2>/dev/null | egrep 'gateway|interface'; echo; networksetup -getdnsservers "$(networksetup -listallnetworkservices 2>/dev/null | sed '1d' | grep -v '^\*' | head -1)" 2>/dev/null; pause;;
 2) run_title 'NETWORK INTERFACES'; ifconfig; pause;;
 3) run_title 'ROUTE & DNS'; route -n get default 2>/dev/null; echo; scutil --dns 2>/dev/null | head -180; pause;;
 4) run_title 'INTERNET DIAGNOSTIC WIZARD'; iface=$(active_iface); ip=$(primary_ip); gw=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}'); [ -n "$iface" ] && echo "PASS: Active interface $iface" || echo 'FAIL: No default interface'; [ -n "$ip" ] && echo "PASS: IP address $ip" || echo 'FAIL: No IP address'; ping -c 1 -W 1000 "$gw" >/dev/null 2>&1 && echo "PASS: Gateway reachable ($gw)" || echo "FAIL: Gateway not reachable ($gw)"; ping -c 1 -W 1000 1.1.1.1 >/dev/null 2>&1 && echo 'PASS: Internet IP reachable' || echo 'FAIL: Internet IP test failed'; dscacheutil -q host -a name apple.com 2>/dev/null | grep -q ip_address && echo 'PASS: DNS resolution works' || echo 'FAIL: DNS resolution failed'; pause;;
 5) run_title 'PING'; printf 'Target hostname/IP: '; read t; ping -c 4 "$t"; pause;;
 6) run_title 'TRACEROUTE'; printf 'Target hostname/IP: '; read t; traceroute "$t"; pause;;
 7) run_title 'DNS LOOKUP'; printf 'Hostname: '; read t; dscacheutil -q host -a name "$t"; pause;;
 8) run_title 'CONNECTIONS'; netstat -anv | egrep 'LISTEN|ESTABLISHED' | head -120; pause;;
 9) run_title 'FLUSH DNS'; if confirm 'Flush DNS cache?'; then sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder 2>/dev/null; echo 'DNS cache flush requested.'; fi; pause;;
 10) run_title 'RENEW DHCP'; iface=$(active_iface); if [ -n "$iface" ] && confirm "Renew DHCP on $iface?"; then sudo ipconfig set "$iface" DHCP; fi; pause;;
 0) return;; esac
 done
}

wifi_center(){
 run_title 'WI-FI INFORMATION';
 wd=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $2; exit}')
 echo "Wi-Fi device: ${wd:-Not available}"; [ -n "$wd" ] && networksetup -getairportpower "$wd" 2>/dev/null
 echo; echo 'Current Wi-Fi details:'
 if [ -x /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport ]; then /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null; else system_profiler SPAirPortDataType 2>/dev/null | sed -n '1,120p'; fi
}

security_center(){
 run_title 'SECURITY CENTRE'
 echo 'FileVault:'; fdesetup status 2>/dev/null; echo
 echo 'Firewall:'; /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null; /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null; echo
 echo 'System Integrity Protection:'; csrutil status 2>/dev/null; echo
 echo 'Gatekeeper:'; spctl --status 2>/dev/null; echo
 echo 'Remote Login (SSH):'; systemsetup -getremotelogin 2>/dev/null || echo 'Admin permission may be required to query.'; echo
 echo 'Remote Apple Events:'; systemsetup -getremoteappleevents 2>/dev/null || true; echo
 echo 'Listening TCP ports:'; lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | head -40 || netstat -an | grep LISTEN | head -40
}

applications_info(){ run_title 'APPLICATION INVENTORY'; find /Applications "$HOME/Applications" -maxdepth 2 -name '*.app' -print 2>/dev/null | sort; echo; echo "Total apps: $(find /Applications "$HOME/Applications" -maxdepth 2 -name '*.app' 2>/dev/null | wc -l | xargs)"; }
startup_items(){ run_title 'STARTUP / LOGIN ITEMS'; echo 'Login Items:'; osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || echo 'Permission may be required.'; echo; echo 'User LaunchAgents:'; ls -1 "$HOME/Library/LaunchAgents" 2>/dev/null || true; echo; echo 'System LaunchAgents:'; ls -1 /Library/LaunchAgents 2>/dev/null || true; echo; echo 'System LaunchDaemons:'; ls -1 /Library/LaunchDaemons 2>/dev/null || true; }
user_info(){ run_title 'USER ACCOUNTS'; echo 'Current user:'; id; echo; echo 'Local user accounts:'; dscl . list /Users UniqueID 2>/dev/null | awk '$2>=500{print}'; echo; echo 'Admin group:'; dscl . -read /Groups/admin GroupMembership 2>/dev/null; echo; echo 'Recent logins:'; last | head -25; }
connected_devices(){ run_title 'CONNECTED DEVICES'; echo 'USB:'; system_profiler SPUSBDataType 2>/dev/null; echo; echo 'Thunderbolt:'; system_profiler SPThunderboltDataType 2>/dev/null; echo; echo 'Displays:'; system_profiler SPDisplaysDataType 2>/dev/null; }
printers(){ run_title 'PRINTER CENTRE'; lpstat -p -d 2>/dev/null || echo 'No printer information available.'; echo; lpstat -o 2>/dev/null || true; }
audio_info(){ run_title 'AUDIO DEVICES'; system_profiler SPAudioDataType 2>/dev/null; }
bluetooth_info(){ run_title 'BLUETOOTH DEVICES'; system_profiler SPBluetoothDataType 2>/dev/null; }
software_updates(){ run_title 'macOS SOFTWARE UPDATE'; echo 'Checking with built-in softwareupdate...'; softwareupdate -l 2>&1; }

safe_repairs(){
 while true; do header; echo 'SAFE REPAIR CENTRE'; echo; printf ' 1. Flush DNS cache [Admin]\n 2. Restart Finder\n 3. Restart Dock\n 4. Restart audio service [Admin]\n 5. Clear print queue [Admin]\n 6. Rebuild Spotlight index [Admin]\n 7. Renew DHCP [Admin]\n 8. Open Disk Utility\n 9. Open Activity Monitor\n10. Open Network Settings\n 0. Back\n\nSelect: '; read c
 case "$c" in
 1) confirm 'Flush DNS cache?' && { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder 2>/dev/null; }; pause;;
 2) confirm 'Restart Finder?' && killall Finder; pause;;
 3) confirm 'Restart Dock?' && killall Dock; pause;;
 4) confirm 'Restart macOS audio service?' && sudo killall coreaudiod; pause;;
 5) confirm 'Cancel all print jobs?' && cancel -a 2>/dev/null; pause;;
 6) confirm 'Rebuild Spotlight index for /? This can temporarily increase CPU/disk use.' && sudo mdutil -E /; pause;;
 7) iface=$(active_iface); confirm "Renew DHCP on ${iface:-active interface}?" && sudo ipconfig set "$iface" DHCP; pause;;
 8) open -a 'Disk Utility';;
 9) open -a 'Activity Monitor';;
 10) open 'x-apple.systempreferences:com.apple.Network-Settings.extension' 2>/dev/null || open -a 'System Settings';;
 0) return;; esac
 done
}

cleanup_center(){
 run_title 'SAFE CLEANUP CENTRE - SCAN ONLY'
 echo 'Nothing is deleted automatically.'; echo
 cache=$(du -sh "$HOME/Library/Caches" 2>/dev/null | awk '{print $1}'); trash=$(du -sh "$HOME/.Trash" 2>/dev/null | awk '{print $1}'); logs=$(du -sh "$HOME/Library/Logs" 2>/dev/null | awk '{print $1}')
 echo "User Caches : ${cache:-N/A}"; echo "Trash       : ${trash:-N/A}"; echo "User Logs   : ${logs:-N/A}"; echo
 echo 'Largest cache folders:'; du -sh "$HOME/Library/Caches"/* 2>/dev/null | sort -h | tail -15
 echo; echo 'For safety, v3.0 reports cleanup opportunities but does not bulk-delete application caches.'
}

log_analyzer(){ run_title 'SYSTEM LOG ANALYZER'; echo 'Recent errors/faults (last 1 hour):'; log show --last 1h --style compact --predicate 'messageType == error OR messageType == fault' 2>/dev/null | tail -120; }
crash_analyzer(){ run_title 'CRASH REPORT ANALYZER'; echo 'Recent Diagnostic Reports (last 7 days):'; find "$HOME/Library/Logs/DiagnosticReports" /Library/Logs/DiagnosticReports -type f -mtime -7 2>/dev/null | sort | tail -80; }
shutdown_analyzer(){ run_title 'SHUTDOWN / RESTART ANALYZER'; echo 'Recent shutdown/reboot history:'; last shutdown reboot | head -40; echo; echo 'Previous shutdown cause entries (if exposed):'; log show --last 7d --style compact --predicate 'eventMessage CONTAINS[c] "Previous shutdown cause"' 2>/dev/null | tail -30; }

create_case(){
 run_title 'CREATE SUPPORT CASE'; printf 'Case title/problem: '; read title; printf 'User/customer: '; read who; printf 'Technician: '; read tech; printf 'Notes: '; read notes
 id="CASE-$(date '+%Y%m%d-%H%M%S')"; f="$CASES/$id.txt"
 { echo "Case ID: $id"; echo "Created: $(date)"; echo "Status: Open"; echo "Computer: $(computer_name)"; echo "Serial: $(serial_number)"; echo "macOS: $(sw_vers -productVersion)"; echo "User/Customer: $who"; echo "Technician: $tech"; echo "Problem: $title"; echo "Notes: $notes"; } > "$f"
 echo; echo "Created: $f"
}
list_cases(){ run_title 'SUPPORT CASES'; ls -lt "$CASES" 2>/dev/null || true; }
case_menu(){ while true; do header; echo 'SUPPORT CASE MANAGEMENT'; echo; printf '1. Create case\n2. List cases\n3. Open cases folder in Finder\n0. Back\n\nSelect: '; read c; case "$c" in 1) create_case; pause;; 2) list_cases; pause;; 3) open "$CASES";; 0) return;; esac; done; }

asset_inventory(){
 out="$INVENTORY/asset-$(date '+%Y%m%d-%H%M%S').txt"
 { echo 'MAC ASSET INVENTORY'; echo "Captured: $(date)"; echo "Computer Name: $(computer_name)"; echo "Serial Number: $(serial_number)"; echo "Model: $(mac_model)"; echo "Chip/CPU: $(mac_chip)"; echo "macOS: $(sw_vers -productVersion)"; echo "Build: $(sw_vers -buildVersion)"; echo "RAM Bytes: $(sysctl -n hw.memsize 2>/dev/null)"; echo "Username: $(whoami)"; echo "Active Interface: $(active_iface)"; echo "IP: $(primary_ip)"; echo "FileVault: $(fdesetup status 2>/dev/null)"; } > "$out"
 run_title 'ASSET INVENTORY'; cat "$out"; echo; echo "Saved: $out"
}

html_report(){
 out="$REPORTS/mac-report-$(date '+%Y%m%d-%H%M%S').html"; battery_data
 fv=$(fdesetup status 2>/dev/null | sed 's/&/\&amp;/g'); sip=$(csrutil status 2>/dev/null | sed 's/&/\&amp;/g'); gk=$(spctl --status 2>/dev/null | sed 's/&/\&amp;/g'); disk=$(df -h / | awk 'NR==2{print $3" / "$2" ("$5")"}')
 cat > "$out" <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Mac IT Report</title><style>body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;max-width:1000px;margin:40px auto;padding:0 24px;color:#1d1d1f}h1{margin-bottom:4px}h2{border-bottom:1px solid #ddd;padding-bottom:8px}table{border-collapse:collapse;width:100%}td{padding:8px;border-bottom:1px solid #eee}td:first-child{font-weight:600;width:35%}.muted{color:#666}</style></head><body>
<h1>macOS IT Operations Report</h1><div class="muted">Generated $(date)</div>
<h2>Device</h2><table><tr><td>Computer</td><td>$(computer_name)</td></tr><tr><td>Serial</td><td>$(serial_number)</td></tr><tr><td>Model</td><td>$(mac_model)</td></tr><tr><td>Chip/CPU</td><td>$(mac_chip)</td></tr><tr><td>macOS</td><td>$(sw_vers -productVersion) ($(sw_vers -buildVersion))</td></tr><tr><td>Storage</td><td>$disk</td></tr></table>
<h2>Battery</h2><table><tr><td>Charge Remaining</td><td>${B_PM_PCT:-N/A}%</td></tr><tr><td>Current Capacity</td><td>${B_CUR:-N/A} mAh</td></tr><tr><td>Full Charge Capacity</td><td>${B_MAX:-N/A} mAh</td></tr><tr><td>Design Capacity</td><td>${B_DES:-N/A} mAh</td></tr><tr><td>Cycle Count</td><td>${B_CYCLE:-N/A}</td></tr><tr><td>Condition</td><td>${B_COND:-N/A}</td></tr></table>
<h2>Network</h2><table><tr><td>Interface</td><td>$(active_iface)</td></tr><tr><td>IP Address</td><td>$(primary_ip)</td></tr></table>
<h2>Security</h2><table><tr><td>FileVault</td><td>$fv</td></tr><tr><td>SIP</td><td>$sip</td></tr><tr><td>Gatekeeper</td><td>$gk</td></tr></table>
</body></html>
HTML
 run_title 'HTML REPORT GENERATED'; echo "$out"; echo; printf 'Open report in browser now? [y/N]: '; read a; case "$a" in y|Y) open "$out";; esac
}

quick_actions(){
 while true; do header; echo 'QUICK ACTIONS'; echo; printf ' 1. Show IP address\n 2. Show serial number\n 3. Battery status\n 4. Disk space\n 5. Restart Finder\n 6. Restart Dock\n 7. Flush DNS [Admin]\n 8. Open Activity Monitor\n 9. Open Disk Utility\n10. Open System Settings\n11. Open Software Update\n12. Open Printers settings\n 0. Back\n\nSelect: '; read c
 case "$c" in 1) echo "IP: $(primary_ip)"; pause;; 2) echo "Serial: $(serial_number)"; pause;; 3) battery_report; pause;; 4) df -h /; pause;; 5) confirm 'Restart Finder?' && killall Finder; pause;; 6) confirm 'Restart Dock?' && killall Dock; pause;; 7) confirm 'Flush DNS?' && { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder 2>/dev/null; }; pause;; 8) open -a 'Activity Monitor';; 9) open -a 'Disk Utility';; 10) open -a 'System Settings';; 11) open 'x-apple.systempreferences:com.apple.Software-Update-Settings.extension' 2>/dev/null || open -a 'System Settings';; 12) open 'x-apple.systempreferences:com.apple.Print-Scan-Settings.extension' 2>/dev/null || open -a 'System Settings';; 0) return;; esac
 done
}

search_tools(){
 run_title 'SEARCH TOOLS'; printf 'Search term (battery, network, storage, security, crash, printer, app, user, update): '; read q
 q=$(printf '%s' "$q" | tr '[:upper:]' '[:lower:]')
 case "$q" in *batt*|*power*) battery_report;; *net*|*dns*|*internet*) network_center;; *wifi*) wifi_center;; *stor*|*disk*) storage_analyzer;; *secur*|*firewall*|*filevault*) security_center;; *crash*) crash_analyzer;; *log*) log_analyzer;; *print*) printers;; *app*) applications_info;; *user*) user_info;; *update*) software_updates;; *) echo 'No direct match. Use the main menu for all available tools.';; esac
}

system_menu(){ while true; do header; echo 'SYSTEM & HARDWARE'; echo; printf '1. Hardware information\n2. Storage analyzer\n3. Battery health & capacity\n4. Performance monitor\n5. Connected devices\n6. User accounts\n7. Applications inventory\n8. Startup / login items\n0. Back\n\nSelect: '; read c; case "$c" in 1) hardware_info; pause;;2) storage_analyzer;pause;;3) battery_report;pause;;4) process_health;pause;;5) connected_devices;pause;;6) user_info;pause;;7) applications_info;pause;;8) startup_items;pause;;0)return;;esac; done; }
peripheral_menu(){ while true; do header; echo 'DEVICES & SERVICES'; echo; printf '1. Wi-Fi information\n2. Printers\n3. Bluetooth\n4. Audio devices\n5. macOS Software Update\n0. Back\n\nSelect: '; read c; case "$c" in 1)wifi_center;pause;;2)printers;pause;;3)bluetooth_info;pause;;4)audio_info;pause;;5)software_updates;pause;;0)return;;esac; done; }
logs_menu(){ while true; do header; echo 'LOGS & ANALYSIS'; echo; printf '1. System error log analyzer\n2. Crash report analyzer\n3. Shutdown/restart analyzer\n4. Open toolkit logs folder\n0. Back\n\nSelect: '; read c; case "$c" in 1)log_analyzer;pause;;2)crash_analyzer;pause;;3)shutdown_analyzer;pause;;4)open "$LOGS";;0)return;;esac; done; }
reports_menu(){ while true; do header; echo 'REPORTS & INVENTORY'; echo; printf '1. Generate HTML IT report\n2. Create asset inventory\n3. Full diagnostic text report\n4. Open reports folder\n5. Open inventory folder\n0. Back\n\nSelect: '; read c; case "$c" in 1)html_report;pause;;2)asset_inventory;pause;;3)full_diagnostic_to_file;pause;;4)open "$REPORTS";;5)open "$INVENTORY";;0)return;;esac; done; }

main(){
 log_msg 'Toolkit started'
 while true; do
  header
  printf ' 1. System Dashboard\n 2. Run Full Mac Diagnostic\n 3. System & Hardware Centre\n 4. Network & Internet Centre\n 5. Security Centre\n 6. Devices & Services\n 7. Safe Repair Centre\n 8. Safe Cleanup Centre\n 9. Logs & Analysis\n10. Support Case Management\n11. Reports & Asset Inventory\n12. Quick Actions\n13. Search Tools\n\n 0. Exit\n\nSelect: '
  read c
  case "$c" in
   1) system_dashboard; pause;; 2) full_diagnostic_to_file; pause;; 3) system_menu;; 4) network_center;; 5) security_center; pause;; 6) peripheral_menu;; 7) safe_repairs;; 8) cleanup_center; pause;; 9) logs_menu;; 10) case_menu;; 11) reports_menu;; 12) quick_actions;; 13) search_tools; pause;; 0) log_msg 'Toolkit exited'; clear; exit 0;; *) sleep 1;;
  esac
 done
}

main
