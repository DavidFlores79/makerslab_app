# Gamepad Module Command Map

## Overview
This document maps the complete command protocol between the Flutter app and Arduino/ESP32 for the gamepad-controlled robot module. The robot features motor control (forward/backward/turn) and servo control (lift, gripper).

---

## Command Protocol

### System Commands
| Command | Description | Response |
|---------|-------------|----------|
| `P\n` or `p\n` | Ping (connection test) | `K\n` |

### Movement Commands (Motors)
| Command | App Control | Robot Action | Motors Used |
|---------|-------------|--------------|-------------|
| `S00` | Joystick center/release | **STOP** all motors | All motors off |
| `F01` | Joystick UP | **Move FORWARD** | IN1/IN2 (left) + IN3/IN4 (right) forward |
| `B01` | Joystick DOWN | **Move BACKWARD** | IN1/IN2 (left) + IN3/IN4 (right) reverse |
| `R01` | Joystick LEFT | **Turn RIGHT** (in place) | Left motor forward + Right motor backward |
| `L01` | Joystick RIGHT | **Turn LEFT** (in place) | Left motor backward + Right motor forward |

### Action Commands (Servos)
| Command | App Button | Icon | Color | Robot Action |
|---------|------------|------|-------|--------------|
| `Y00` | Triangle (top) | ▲ | Green | **Lift servos UP** (raise arms to 80°) |
| `A00` | X (bottom) | ✕ | Blue | **Smart sequence**: Release → Lower → Pickup |
| `X00` | Square (left) | ■ | Purple | **Release object** (open gripper to 90°) |
| `B00` | Circle (right) | ○ | Red | **Pick up object** (close gripper to 170°) |

### Side Control Commands
| Command | App Button | Robot Action | Status |
|---------|------------|--------------|--------|
| `L02` | L button | Return container back | **Disabled on UNO** |
| `R02` | R button | Empty trash container (lift to 150°) | **ESP32 only** |

---

## Joystick Mapping Details

The on-screen joystick directions are **intentionally rotated** to match the physical robot orientation:

```
Phone Screen               Arduino/ESP32 Command       Robot Action
────────────────────────────────────────────────────────────────────
   ↑ (Up)         →         R01                  →    Turn RIGHT
   ↓ (Down)       →         L01                  →    Turn LEFT
   ← (Left)       →         B01                  →    Move BACKWARD
   → (Right)      →         F01                  →    Move FORWARD
   ● (Center)     →         S00                  →    STOP
```

**Why this mapping?**  
The phone is held horizontally, and the robot's "forward" direction corresponds to the user's right. This rotation provides intuitive control from the operator's perspective.

---

## Hardware Connections

### ESP32 Pin Configuration
```
Motor Driver (L298N):
  - IN1  → GPIO 25  (Left motor direction A)
  - IN2  → GPIO 26  (Left motor direction B)
  - IN3  → GPIO 27  (Right motor direction A)
  - IN4  → GPIO 14  (Right motor direction B)
  - VCC  → External 6-12V power supply
  - GND  → Shared GND with ESP32

Servos:
  - Servo Right   → GPIO 2   (Right arm servo)
  - Servo Left    → GPIO 15  (Left arm servo)
  - Gripper Right → GPIO 4   (Right gripper servo)
  - Gripper Left  → GPIO 5   (Left gripper servo)
  - Servo Lift    → GPIO 18  (Lift mechanism servo)
  - VCC           → 5V (or external if high current)
  - GND           → Shared GND with ESP32

Bluetooth:
  - Built-in Bluetooth Classic (no external module needed)
  - Device name: "ESP32_Gamepad"
```

### Arduino UNO Pin Configuration
```
Bluetooth Module (HC-05):
  - RX  → Pin 10  (SoftwareSerial)
  - TX  → Pin 11  (SoftwareSerial)
  - VCC → 5V
  - GND → GND

Motor Driver (L298N):
  - IN1  → Pin 4  (Left motor direction A)
  - IN2  → Pin 5  (Left motor direction B)
  - IN3  → Pin 6  (Right motor direction A)
  - IN4  → Pin 7  (Right motor direction B)
  - VCC  → External 6-12V power supply
  - GND  → Shared GND with Arduino

Servos:
  - Servo Right   → Pin 2   (Right arm servo)
  - Servo Left    → Pin 8   (Left arm servo)
  - Gripper Right → Pin 12  (Right gripper servo)
  - Gripper Left  → Pin 9   (Left gripper servo)
  - Servo Lift    → Pin 13  (Lift mechanism servo)
  - VCC           → 5V (or external if high current)
  - GND           → Shared GND with Arduino
```

---

## Motor Speed Calibration

Both sketches include motor speed balancing multipliers:
- **Left Motor Multiplier**: `1.00` (100% speed)
- **Right Motor Multiplier**: `0.70` (70% speed)

These compensate for physical differences between motors. Adjust in the sketch if your robot drifts during straight movement.

---

## Command Format

All commands follow this structure:
```
<COMMAND>\n
```
- Commands are **3 characters** (e.g., `F01`, `S00`, `Y00`)
- Terminated with **newline character** (`\n`)
- Case-sensitive (except for ping: `P` or `p`)
- Carriage return (`\r`) is ignored

### Example Command Sequence
```
1. App sends: P\n          → Arduino responds: K\n
2. User pushes joystick forward
   App sends: F01\n        → Robot moves forward
3. User releases joystick
   App sends: S00\n        → Robot stops
4. User presses circle button
   App sends: B00\n        → Gripper closes (pickup)
```

---

## Servo Position Details

### Gripper Servos (Left/Right symmetric)
- **Open (release)**: 90° (left) / 90° (right)
- **Closed (pickup)**: 170° (left) / 10° (right)
- **Animation**: Gradual movement with 5ms delay per degree

### Lift/Arm Servos (Left/Right symmetric)
- **Down position**: 1° (left) / 179° (right)
- **Middle position**: 70° (left) / 110° (right)
- **Up position**: 80° (left) / 100° (right)
- **Animation**: Gradual movement with 5ms delay per degree

### Container Lift Servo (`R02` command - ESP32 only)
- **Down position**: 0°
- **Up position (empty)**: 150°

---

## App Implementation Details

### Flutter App Components
- **Repository**: `lib/features/gamepad/data/repositories/gamepad_repository_impl.dart`
- **BLoC**: `lib/features/gamepad/presentation/bloc/gamepad_bloc.dart`
- **UI**: `lib/features/gamepad/presentation/widgets/gamepad_interface_page.dart`
- **Joystick Library**: `simple_joystick` package

### Key Features
1. **Command Queueing**: Prevents Bluetooth buffer overflow
2. **Heartbeat**: Periodic ping to detect disconnection
3. **Timeout Detection**: Auto-stops robot if connection lost
4. **Command Throttling**: Prevents duplicate commands
5. **Periodic Refresh**: Repeats movement commands every 100ms while joystick is held

---

## Testing Checklist

### Connection Test
- [ ] App can discover device (`ESP32_Gamepad` or HC-05)
- [ ] Successful Bluetooth pairing
- [ ] Ping command receives `K` response

### Motor Tests
- [ ] Forward command moves robot forward
- [ ] Backward command moves robot backward
- [ ] Right/Left commands turn robot in place
- [ ] Stop command halts all motors
- [ ] Robot stops when joystick released

### Servo Tests
- [ ] Triangle button lifts arms up
- [ ] Circle button closes gripper
- [ ] Square button opens gripper
- [ ] X button executes full pickup sequence

### Safety Tests
- [ ] Robot stops when app disconnects
- [ ] Robot stops when Bluetooth connection lost
- [ ] Emergency stop via joystick release works

---

## Troubleshooting

### Robot doesn't move
- Check motor driver connections (IN1-IN4)
- Verify external power supply is connected
- Check motor driver enable pins (if applicable)
- Test with direct motor driver commands

### Robot turns when moving straight
- Adjust motor speed multipliers in Arduino code
- Check wheel alignment
- Verify both motors have same voltage

### Servos don't respond
- Check servo power supply (5V required)
- Verify servo signal pins are correct
- Test servo positions manually via Arduino Serial Monitor
- Ensure servos are properly attached in `setup()`

### Bluetooth connection issues
- **UNO**: Set HC-05 baud rate to 9600 (AT+UART=9600,0,0)
- **ESP32**: Ensure Bluetooth Classic is enabled in menuconfig
- Check device name matches in app
- Reset Bluetooth module and re-pair

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│           GAMEPAD COMMAND QUICK REFERENCE           │
├─────────────────────────────────────────────────────┤
│  MOVEMENT                                           │
│    S00 = Stop       F01 = Forward                  │
│    B01 = Backward   R01 = Turn Right               │
│    L01 = Turn Left                                 │
├─────────────────────────────────────────────────────┤
│  ACTIONS                                            │
│    Y00 = Lift Up    B00 = Pick Up (close gripper) │
│    X00 = Release    A00 = Smart pickup sequence   │
│    L02 = Return     R02 = Empty container         │
├─────────────────────────────────────────────────────┤
│  SYSTEM                                             │
│    P = Ping         Response: K                    │
└─────────────────────────────────────────────────────┘
```

---

## Related Files

- **ESP32 Sketch**: `assets/files/esp32_bt_gamepad/esp32_bt_gamepad.ino`
- **UNO Sketch**: `assets/files/UNO_bt_gamepad/UNO_bt_gamepad.ino`
- **Flutter Implementation**: `lib/features/gamepad/`
- **Instructions**: `assets/images/static/gamepad/instructions/`

---

**Last Updated**: March 2026  
**Compatible Versions**: ESP32 Arduino Core 2.x, Arduino UNO R3, Flutter 3.7.2+
