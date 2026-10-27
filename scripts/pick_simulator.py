"""Prints the UDID of an available iPhone simulator with the newest iOS version.

Reads the output of `xcrun simctl list devices available --json`, so nothing
(device name or iOS version) is hardcoded.
"""
import json
import re
import subprocess
import sys

output = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"])
devices_by_runtime = json.loads(output)["devices"]

candidates = []
for runtime, devices in devices_by_runtime.items():
    # Runtime looks like "com.apple.CoreSimulator.SimRuntime.iOS-18-2".
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    if version < (17, 0):  # the app needs iOS 17+
        continue
    for device in devices:
        if device["name"].startswith("iPhone"):
            candidates.append((version, device["name"], device["udid"]))

if not candidates:
    sys.exit("No iPhone simulator with iOS 17 or newer is available")

version, name, udid = max(candidates)
print(f"Using {name} (iOS {version[0]}.{version[1]})", file=sys.stderr)
print(udid)
