# 📟 PicoMite / PicoCalc Serial + XMODEM Setup Guide (macOS)

This guide explains how to connect to a **PicoMite-based device** (like the PicoCalc) from macOS using `picocom`, and how to transfer files via **XMODEM**.  
It includes installation steps, command options, and the correct upload/download sequences.

---

## 🧩 1. Required Tools

Install the following via [Homebrew](https://brew.sh):

```bash
brew install picocom lrzsz
```

| Tool | Purpose |
|------|----------|
| **picocom** | Lightweight serial terminal emulator |
| **lrzsz** | Provides `lrx` / `lsx` for XMODEM/YMODEM/ZMODEM file transfers |

Verify installation:

```bash
which picocom
which lsx
which lrx
```

Expected paths (on Apple Silicon):

```
/opt/homebrew/bin/picocom
/opt/homebrew/bin/lsx
/opt/homebrew/bin/lrx
```

---

## ⚙️ 2. Connect to the Device

Example command:

```bash
picocom -b 115200 --imap delbs --omap delbs   --send-cmd "/opt/homebrew/bin/lsx -vv"   --receive-cmd "/opt/homebrew/bin/lrx"   -vv /dev/cu.usbserial-210
```

### Option Breakdown

| Option | Description |
|--------|--------------|
| `-b 115200` | Sets the baud rate (communication speed) to 115,200 baud |
| `--imap delbs` | Input map: treat Delete as Backspace |
| `--omap delbs` | Output map: treat Delete as Backspace on output |
| `--send-cmd "/opt/homebrew/bin/lsx -vv"` | Command used when sending a file (XMODEM upload) |
| `--receive-cmd "/opt/homebrew/bin/lrx"` | Command used when receiving a file (XMODEM download) |
| `-vv` | Verbose mode for diagnostic output |
| `/dev/cu.usbserial-210` | Serial device name (check with `ls /dev/cu.*`) |

When the connection is established, picocom prints configuration info like:

```
port is        : /dev/cu.usbserial-210
flowcontrol    : none
baudrate is    : 115200
parity is      : none
databits are   : 8
stopbits are   : 1
escape is      : C-a
local echo is  : no
send_cmd is    : /opt/homebrew/bin/lsx -vv
receive_cmd is : /opt/homebrew/bin/lrx
imap is        : delbs,
omap is        : delbs,
emap is        : crcrlf,delbs,
```

Once you see `Terminal ready`, you’re connected to the PicoMite console.

---

## 🧾 3. Common Picocom Commands

| Shortcut | Description |
|-----------|-------------|
| `Ctrl-A Ctrl-H` | Show help (lists all shortcuts) |
| `Ctrl-A Ctrl-X` | Exit |
| `Ctrl-A Ctrl-Q` | Exit without resetting port |
| `Ctrl-A Ctrl-U` | Toggle local echo |
| `Ctrl-A Ctrl-S` | Send file (upload via `lsx`) |
| `Ctrl-A Ctrl-R` | Receive file (download via `lrx`) |
| `Ctrl-A Ctrl-L` | Toggle session logging |

---

## 🚀 4. Sending a File to the PicoMite (Mac → Device)

### Step 1. On the PicoMite
At the `>` prompt, type:
```basic
XMODEM RECEIVE "PROGRAM.BAS"
```
and press Enter.  
The device will display:
```
Ready to receive via XMODEM
```

### Step 2. On the Mac (inside picocom)
Press:
```
Ctrl-A S
```
Picocom will prompt for the file to send and automatically run `lsx`.  
You’ll see something like:
```
*** file: PROGRAM.BAS
Sending PROGRAM.BAS, 33 blocks: Give your local XMODEM receive command now.
```

The transfer then proceeds automatically.  
When complete, you’ll see a summary such as:
```
Bytes Sent: 4224   BPS:11520   Blocks:33
Transfer complete
```

### Step 3. Verify on the PicoMite
At the prompt:
```basic
FILES
```
to list files, or:
```basic
EDIT "PROGRAM.BAS"
```
to open and confirm.

---

## ⬇️ 5. Receiving a File from the PicoMite (Device → Mac)

### Step 1. On the PicoMite
At the prompt:
```basic
XMODEM SEND "PROGRAM.BAS"
```

### Step 2. On the Mac
In picocom, press:
```
Ctrl-A R
```
Picocom launches the configured `lrx` command, and the file will be saved in your current terminal directory.

---

## 📚 6. Quick Direction Reference

| Direction | PicoMite Command | Picocom Shortcut | Transfer Utility |
|------------|------------------|------------------|------------------|
| Upload (Mac → Device) | `XMODEM RECEIVE "FILE.BAS"` | `Ctrl-A S` | `lsx` |
| Download (Device → Mac) | `XMODEM SEND "FILE.BAS"` | `Ctrl-A R` | `lrx` |

---

## ✅ 7. Summary

- Install `picocom` and `lrzsz` via Homebrew.  
- Use `/dev/cu.usbserial-xxx` for your connected device.  
- Upload with `XMODEM RECEIVE` + `Ctrl-A S`.  
- Download with `XMODEM SEND` + `Ctrl-A R`.  
- Press `Ctrl-A Ctrl-H` anytime for help inside picocom.

---

**Author’s note:**  
This setup provides a stable, minimal, and reproducible serial workflow for developing and transferring `.BAS` programs to PicoMite-based devices. It avoids full-screen terminal tools and works natively on macOS with Homebrew dependencies only.
