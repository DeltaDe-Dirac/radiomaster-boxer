# radiomaster-boxer

## `batt1.lua`

[`scripts/SCRIPTS/TELEMETRY/batt1.lua`](C:/Projects/radiomaster-boxer/scripts/SCRIPTS/TELEMETRY/batt1.lua) is a custom EdgeTX telemetry screen for the RadioMaster Boxer black-and-white display. It is aimed at FPV use and combines battery status, link quality, and post-flight battery health in a single screen.

### What it shows

- Battery status with pack voltage, per-cell voltage, charge percentage, and low/critical visual warnings.
- Link quality with `RQly` plus the stronger of `1RSS` and `2RSS`.
- Flight timer that runs only while the craft is armed.
- Battery health after use, based on per-cell voltage sag from the start of the flight to the minimum seen under load.

### Battery logic

- Auto-detects pack size from `1S` through `6S` using the measured pack voltage.
- Supports manual cell-count override with the `S1` knob.
- Auto-detects standard LiPo vs HV LiPo chemistry and adjusts the full-scale percentage calculation accordingly.
- Detects a newly connected battery and resets internal state for the next pack.

### Alerts and controls

- Low-voltage warnings play `batlow.wav`.
- Critical voltage triggers both haptic feedback and `batcrt.wav`.
- Alerts only run while the craft is armed, so the radio stays quiet on the bench and after landing.
- Long-press `ENTER` while disarmed to reset the displayed flight timer and alert state.

### Current behavior captured in this repo

The current `batt1.lua` version includes two practical fixes:

- New-battery detection is gated to the disarmed state, which prevents a crash-induced voltage rebound from being mistaken for a battery swap.
- The completed-flight screen now shows a reset hint (`H:RST`) and supports manual timer reset with a long press on `ENTER`.
