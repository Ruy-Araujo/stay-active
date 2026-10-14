<p align="center">
  <h1 align="center">stay-active</h1>
  <p align="center">
    <strong>Keep Microsoft Teams (and other apps) showing you as "Active" on macOS and Linux</strong>
  </p>
  <p align="center">
    <a href="https://www.apple.com/macos"><img src="https://img.shields.io/badge/macOS-10.13+-blue.svg?style=for-the-badge&logo=apple" alt="macOS"></a>
    <a href="https://www.x.org/"><img src="https://img.shields.io/badge/Linux-X11-FCC624.svg?style=for-the-badge&logo=linux&logoColor=black" alt="Linux X11"></a>
    <a href="https://wayland.freedesktop.org/"><img src="https://img.shields.io/badge/Linux-Wayland-FCC624.svg?style=for-the-badge&logo=linux&logoColor=black" alt="Linux Wayland"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"></a>
    <a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/Shell-Bash-4EAA25.svg?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Bash"></a>
  </p>
</p>

<p align="center">
  <img src="assets/demo.gif" alt="stay-active demo" width="600">
</p>

<p align="center">
  <em>No more getting marked as "Away" during bathroom breaks, coffee runs, or deep work sessions.</em>
</p>

---

## The Problem

Microsoft Teams marks you as **"Away" after just 5 minutes** of inactivity. There's no built-in setting to change this.

This creates problems:
- Makes you look unproductive during legitimate breaks
- Triggers unnecessary check-ins from managers
- Creates false impressions about your availability
- Penalizes deep work (reading docs, thinking, planning)

## The Solution

`stay-active` simulates natural human activity at random intervals:

| Feature | Description |
|---------|-------------|
| **Mouse Movement** | Tiny, random movements (1-5 pixels) |
| **Keyboard Activity** | Shift key press (invisible, non-disruptive) |
| **Human-like Patterns** | Random intervals (30-60 sec), not predictable |
| **Lightweight** | Pure shell script, ~6KB, no heavy dependencies |
| **Logging** | Built-in activity log to verify it's working |

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ruy-Araujo/stay-active/main/install.sh | bash
```

That's it! The installer handles Homebrew and cliclick on macOS, xdotool on Linux X11, or ydotool on Linux Wayland, then configures PATH.

To install from a local checkout instead of downloading the script, run:

```bash
./install.sh
```

<details>
<summary><strong>Manual Installation</strong></summary>

### macOS

Install cliclick:

```bash
brew install cliclick
```

### Linux X11

Install xdotool with your distribution package manager:

```bash
sudo apt-get install xdotool       # Debian / Ubuntu
sudo dnf install xdotool           # Fedora
sudo pacman -S xdotool             # Arch Linux
sudo zypper install xdotool        # openSUSE
```

### Linux Wayland

Install ydotool with your distribution package manager:

```bash
sudo apt-get install ydotool       # Debian / Ubuntu
sudo dnf install ydotool           # Fedora
sudo pacman -S ydotool             # Arch Linux
sudo zypper install ydotool        # openSUSE
```

`ydotool` requires `ydotoold`, which creates a virtual input device through `/dev/uinput`. Configure and start the daemon manually before running `stay-active`. For example, the following command creates a user-owned socket in the current desktop session:

```bash
sudo ydotoold --socket-path="$XDG_RUNTIME_DIR/.ydotool_socket" --socket-own="$(id -u):$(id -g)" --socket-perm=0600 &
```

The client uses that location by default. If your daemon uses another socket, export its path before starting `stay-active`:

```bash
export YDOTOOL_SOCKET=/path/to/.ydotool_socket
```

Wayland uses relative mouse movement. Pointer acceleration, screen edges, or user input can prevent the return movement from restoring the exact original pixel.

### Download stay-active

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Ruy-Araujo/stay-active/main/stay-active -o ~/.local/bin/stay-active
chmod +x ~/.local/bin/stay-active
```

### Add to PATH

```bash
# Zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Grant Accessibility Permissions on macOS

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click **+** and add **Terminal** (or your terminal app)
3. Also add `/opt/homebrew/bin/cliclick`

</details>

---

## Usage

```bash
stay-active start     # Start keeping you active
stay-active stop      # Stop the daemon
stay-active toggle    # Toggle on/off
stay-active status    # Check if running
stay-active log       # View activity log
stay-active --help    # Show all commands
```

### Example

```bash
$ stay-active start
Started (PID: 12345)

$ stay-active status
Running (PID: 12345)

$ stay-active log
[2025-01-15 09:30:45] Daemon started (v1.0.0)
[2025-01-15 09:30:45] Activity: mouse (500,400)->(503,398) + shift key
[2025-01-15 09:30:45] Sleeping 42s
...
```

---

## How It Works

```
Every 30-60 seconds (randomized):
  1. Move mouse 1-5 pixels in random direction
  2. Press + release Shift key
  3. 60% chance: move mouse back to original position
  4. 15% of cycles: use shorter 15-30 sec intervals
```

This mimics natural human behavior — no predictable patterns that could be flagged.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **macOS** | 10.13 (High Sierra) or newer, Homebrew, cliclick, and Accessibility access |
| **Linux X11** | X11 session with xdotool |
| **Linux Wayland** | ydotool and a running ydotoold with access to `/dev/uinput` |

---

## Troubleshooting

<details>
<summary><strong>"cliclick not found"</strong></summary>

```bash
brew install cliclick
```
</details>

<details>
<summary><strong>"xdotool not found"</strong></summary>

Install it with your distribution package manager, for example:

```bash
sudo apt-get install xdotool
```
</details>

<details>
<summary><strong>"ydotool not found" or "Cannot access ydotoold"</strong></summary>

Install ydotool, then start `ydotoold` with access to `/dev/uinput` and a socket your user can access. Set `YDOTOOL_SOCKET` if the daemon does not use `$XDG_RUNTIME_DIR/.ydotool_socket`.
</details>

<details>
<summary><strong>"DISPLAY is not set"</strong></summary>

Start `stay-active` from an X11 session, or use a Wayland session with ydotool configured.
</details>

<details>
<summary><strong>"Accessibility privileges not enabled"</strong></summary>

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Add your terminal app (Terminal, iTerm, etc.)
3. Add `/opt/homebrew/bin/cliclick`
</details>

<details>
<summary><strong>Teams still shows "Away"</strong></summary>

1. Check the log: `stay-active log`
2. Verify it's running: `stay-active status`
3. Restart: `stay-active stop && stay-active start`
4. Make sure Accessibility permissions are granted
</details>

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Ruy-Araujo/stay-active/main/uninstall.sh | bash
```

<details>
<summary><strong>Manual uninstall</strong></summary>

```bash
stay-active stop
rm ~/.local/bin/stay-active
rm ~/.local/.stay_active_*
brew uninstall cliclick  # optional on macOS
# Remove xdotool or ydotool with your package manager  # optional on Linux
```
</details>

---

## Privacy & Security

- **100% Local** — No data sent anywhere, no analytics
- **Offline** — Works without internet
- **Open Source** — Review every line of code
- **Minimal** — Only needs Accessibility permission

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

**Ideas:**
- [x] Linux X11 support (xdotool)
- [x] Linux Wayland support (ydotool)
- [ ] Windows support (PowerShell)
- [ ] Configurable intervals
- [ ] Schedule mode (work hours only)
- [ ] Native menu bar app

---

## License

[MIT](LICENSE) — Do whatever you want with it.

---

<p align="center">
  <strong>Made by <a href="https://github.com/sleekhost">Sleekhost</a></strong>
</p>

<p align="center">
  <em>If this helped you, consider giving it a ⭐</em>
</p>
