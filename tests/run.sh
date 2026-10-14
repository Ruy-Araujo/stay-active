#!/bin/bash

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEMP_DIR=$(mktemp -d)
BIN_DIR="$TEMP_DIR/bin"
HOME_DIR="$TEMP_DIR/home"
mkdir -p "$BIN_DIR" "$HOME_DIR"

cleanup() {
    if [ -f "$HOME_DIR/.local/.stay_active_pid" ]; then
        kill "$(cat "$HOME_DIR/.local/.stay_active_pid")" 2>/dev/null || true
    fi
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "expected '$2' in '$1'" ;;
    esac
}

assert_not_contains() {
    case "$1" in
        *"$2"*) fail "did not expect '$2' in '$1'" ;;
        *) ;;
    esac
}

assert_success() {
    "$@" || fail "expected success: $*"
}

assert_failure() {
    if "$@"; then
        fail "expected failure: $*"
    fi
}

wait_for_log() {
    expected=$1
    attempts=0
    while [ "$attempts" -lt 20 ]; do
        if [ -f "$HOME_DIR/.local/.stay_active_log" ] && grep -q "$expected" "$HOME_DIR/.local/.stay_active_log"; then
            return
        fi
        /usr/bin/sleep 0.01
        attempts=$((attempts + 1))
    done
    fail "timed out waiting for '$expected'"
}

write_mock_tools() {
    cat > "$BIN_DIR/uname" << 'EOF'
#!/bin/bash
echo "${MOCK_PLATFORM:-Linux}"
EOF
    cat > "$BIN_DIR/xdotool" << 'EOF'
#!/bin/bash
echo "$*" >> "$MOCK_LOG"
if [ "$1" = "getmouselocation" ]; then
    case "${MOCK_XDOTOOL_MODE:-ok}" in
        ok) printf 'X=500\nY=400\nSCREEN=0\nWINDOW=1\n' ;;
        invalid) printf 'X=invalid\nY=400\n' ;;
        fail) exit 1 ;;
    esac
fi
if [ "$1" = "mousemove" ] && [ "${MOCK_MOUSEMOVE_FAIL:-}" = "1" ]; then exit 1; fi
if [ "$1" = "key" ] && [ "${MOCK_KEY_FAIL:-}" = "1" ]; then exit 1; fi
EOF
    cat > "$BIN_DIR/cliclick" << 'EOF'
#!/bin/bash
echo "$*" >> "$MOCK_LOG"
if [ "$1" = "p" ]; then printf '500,400\n'; fi
EOF
    cat > "$BIN_DIR/sleep" << 'EOF'
#!/bin/bash
/usr/bin/sleep 0.01
EOF
    chmod +x "$BIN_DIR"/*
}

reset_case() {
    if [ -f "$HOME_DIR/.local/.stay_active_pid" ]; then
        MOCK_PLATFORM=Linux run_stay_active stop > /dev/null 2>&1 || true
    fi
    rm -rf "$HOME_DIR"
    mkdir -p "$HOME_DIR"
    : > "$TEMP_DIR/activity.log"
}

run_stay_active() {
    HOME="$HOME_DIR" PATH="$BIN_DIR:$PATH" MOCK_LOG="$TEMP_DIR/activity.log" "$ROOT/stay-active" "$@"
}

write_mock_tools

reset_case
output=$(MOCK_PLATFORM=Linux XDG_SESSION_TYPE=wayland DISPLAY=:1 run_stay_active start 2>&1 || true)
assert_contains "$output" "Wayland is not supported"
[ ! -e "$HOME_DIR/.local/.stay_active_on" ] || fail "Wayland created a control file"

reset_case
output=$(MOCK_PLATFORM=Linux XDG_SESSION_TYPE=x11 WAYLAND_DISPLAY=wayland-0 DISPLAY=:1 run_stay_active start 2>&1 || true)
assert_contains "$output" "Wayland is not supported"

reset_case
output=$(MOCK_PLATFORM=Linux DISPLAY= XDG_SESSION_TYPE=x11 run_stay_active start 2>&1 || true)
assert_contains "$output" "DISPLAY is not set"

reset_case
MISSING_XDOTOOL_ENV="$TEMP_DIR/missing-xdotool.sh"
cat > "$MISSING_XDOTOOL_ENV" << 'EOF'
command() {
    if [ "$1" = "-v" ] && [ "$2" = "xdotool" ]; then return 1; fi
    builtin command "$@"
}
EOF
output=$(BASH_ENV="$MISSING_XDOTOOL_ENV" HOME="$HOME_DIR" DISPLAY=:1 XDG_SESSION_TYPE=x11 "$ROOT/stay-active" start 2>&1 || true)
assert_contains "$output" "xdotool not found"

reset_case
output=$(MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 MOCK_XDOTOOL_MODE=fail run_stay_active start 2>&1 || true)
assert_contains "$output" "Cannot access the X11 display"

reset_case
output=$(MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 MOCK_XDOTOOL_MODE=invalid run_stay_active start 2>&1 || true)
assert_contains "$output" "Cannot access the X11 display"

reset_case
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active start
wait_for_log "Activity:"
if MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active start > /dev/null 2>&1; then
    fail "starting an active daemon succeeded"
fi
assert_contains "$(MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active status)" "Running"
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active stop
if MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active status > /dev/null 2>&1; then
    fail "stopped daemon reported running"
fi
activity=$(cat "$TEMP_DIR/activity.log")
assert_contains "$activity" "getmouselocation --shell"
assert_contains "$activity" "mousemove"
assert_contains "$activity" "key Shift_L"

reset_case
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 MOCK_MOUSEMOVE_FAIL=1 run_stay_active start
wait_for_log "Could not move mouse"
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active stop

reset_case
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 MOCK_KEY_FAIL=1 run_stay_active start
wait_for_log "Could not send shift key"
MOCK_PLATFORM=Linux DISPLAY=:1 XDG_SESSION_TYPE=x11 run_stay_active stop

reset_case
MOCK_PLATFORM=Darwin run_stay_active start
wait_for_log "Activity:"
assert_contains "$(MOCK_PLATFORM=Darwin run_stay_active status)" "Running"
assert_contains "$(MOCK_PLATFORM=Darwin run_stay_active log)" "Recent activity:"
MOCK_PLATFORM=Darwin run_stay_active toggle
if MOCK_PLATFORM=Darwin run_stay_active status > /dev/null 2>&1; then
    fail "toggled-off daemon reported running"
fi
MOCK_PLATFORM=Darwin run_stay_active toggle
wait_for_log "Activity:"
MOCK_PLATFORM=Darwin run_stay_active stop
activity=$(cat "$TEMP_DIR/activity.log")
assert_contains "$activity" "p"
assert_contains "$activity" "kd:shift ku:shift"

reset_case
MISSING_CLICLICK_ENV="$TEMP_DIR/missing-cliclick.sh"
cat > "$MISSING_CLICLICK_ENV" << 'EOF'
command() {
    if [ "$1" = "-v" ] && [ "$2" = "cliclick" ]; then return 1; fi
    builtin command "$@"
}
EOF
output=$(BASH_ENV="$MISSING_CLICLICK_ENV" MOCK_PLATFORM=Darwin run_stay_active start 2>&1 || true)
assert_contains "$output" "cliclick not found"

reset_case
output=$(MOCK_PLATFORM=Darwin run_stay_active --help)
assert_contains "$output" "EXAMPLES:"
assert_contains "$output" "Linux X11"
assert_contains "$(MOCK_PLATFORM=Darwin run_stay_active --version)" "stay-active v1.0.0"
if MOCK_PLATFORM=Darwin run_stay_active unknown > /dev/null 2>&1; then
    fail "unknown command succeeded"
fi

run_installer() {
    manager=$1
    install_bin="$TEMP_DIR/installer-$manager"
    rm -rf "$install_bin"
    mkdir -p "$install_bin"
    cp "$BIN_DIR/uname" "$install_bin/uname"
    cat > "$install_bin/id" << 'EOF'
#!/bin/bash
echo 1000
EOF
    cat > "$install_bin/sudo" << 'EOF'
#!/bin/bash
echo "sudo $*" >> "$MOCK_INSTALL_LOG"
"$@"
EOF
    cat > "$install_bin/curl" << 'EOF'
#!/bin/bash
echo "curl $*" >> "$MOCK_INSTALL_LOG"
output=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        output=$2
        shift 2
    else
        shift
    fi
done
printf '#!/bin/bash\n' > "$output"
EOF
    cat > "$install_bin/$manager" << 'EOF'
#!/bin/bash
echo "manager $(basename "$0") $*" >> "$MOCK_INSTALL_LOG"
EOF
    chmod +x "$install_bin"/*
    cat > "$TEMP_DIR/missing-installer-xdotool.sh" << 'EOF'
command() {
    if [ "$1" = "-v" ]; then
        case "$2" in
            xdotool) return 1 ;;
            apt-get|dnf|pacman|zypper)
                [ "$2" = "$MOCK_MANAGER" ]
                return
                ;;
        esac
    fi
    builtin command "$@"
}
EOF
    reset_case
    remote_installer="$TEMP_DIR/remote-install.sh"
    cp "$ROOT/install.sh" "$remote_installer"
    BASH_ENV="$TEMP_DIR/missing-installer-xdotool.sh" MOCK_MANAGER="$manager" MOCK_PLATFORM=Linux MOCK_INSTALL_LOG="$TEMP_DIR/install.log" HOME="$HOME_DIR" SHELL=/bin/bash PATH="$install_bin:/usr/bin:/bin" /usr/bin/bash "$remote_installer"
}

for manager in apt-get dnf pacman zypper; do
    : > "$TEMP_DIR/install.log"
    run_installer "$manager"
    install_log=$(cat "$TEMP_DIR/install.log")
    assert_contains "$install_log" "manager $manager"
    assert_contains "$install_log" "raw.githubusercontent.com/Ruy-Araujo/stay-active"
    assert_contains "$(cat "$HOME_DIR/.bashrc")" '.local/bin'
    [ -x "$HOME_DIR/.local/bin/stay-active" ] || fail "installer did not install executable"
done

reset_case
LOCAL_INSTALL_BIN="$TEMP_DIR/local-install"
rm -rf "$LOCAL_INSTALL_BIN"
mkdir "$LOCAL_INSTALL_BIN"
cp "$BIN_DIR/uname" "$LOCAL_INSTALL_BIN/uname"
cat > "$LOCAL_INSTALL_BIN/xdotool" << 'EOF'
#!/bin/bash
exit 0
EOF
cat > "$LOCAL_INSTALL_BIN/curl" << 'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$LOCAL_INSTALL_BIN"/*
HOME="$HOME_DIR" SHELL=/bin/bash PATH="$LOCAL_INSTALL_BIN:/usr/bin:/bin" MOCK_PLATFORM=Linux /usr/bin/bash "$ROOT/install.sh"
cmp "$ROOT/stay-active" "$HOME_DIR/.local/bin/stay-active" || fail "local installer did not copy the checkout script"

reset_case
FAILED_SUDO_BIN="$TEMP_DIR/failed-sudo"
rm -rf "$FAILED_SUDO_BIN"
mkdir "$FAILED_SUDO_BIN"
cp "$BIN_DIR/uname" "$FAILED_SUDO_BIN/uname"
cat > "$FAILED_SUDO_BIN/id" << 'EOF'
#!/bin/bash
echo 1000
EOF
cat > "$FAILED_SUDO_BIN/sudo" << 'EOF'
#!/bin/bash
exit 1
EOF
cat > "$FAILED_SUDO_BIN/apt-get" << 'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$FAILED_SUDO_BIN"/*
output=$(BASH_ENV="$TEMP_DIR/missing-installer-xdotool.sh" MOCK_MANAGER=apt-get HOME="$HOME_DIR" PATH="$FAILED_SUDO_BIN:/usr/bin:/bin" MOCK_PLATFORM=Linux /usr/bin/bash "$ROOT/install.sh" 2>&1 || true)
assert_contains "$output" "Could not install xdotool"

reset_case
EXISTING_XDOTOOL_BIN="$TEMP_DIR/existing-xdotool"
rm -rf "$EXISTING_XDOTOOL_BIN"
mkdir "$EXISTING_XDOTOOL_BIN"
cp "$BIN_DIR/uname" "$EXISTING_XDOTOOL_BIN/uname"
cat > "$EXISTING_XDOTOOL_BIN/xdotool" << 'EOF'
#!/bin/bash
exit 0
EOF
cat > "$EXISTING_XDOTOOL_BIN/curl" << 'EOF'
#!/bin/bash
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        printf '#!/bin/bash\n' > "$2"
        exit 0
    fi
    shift
done
exit 1
EOF
chmod +x "$EXISTING_XDOTOOL_BIN"/*
output=$(HOME="$HOME_DIR" SHELL=/bin/bash PATH="$EXISTING_XDOTOOL_BIN:/usr/bin:/bin" MOCK_PLATFORM=Linux /usr/bin/bash "$ROOT/install.sh")
assert_contains "$output" "xdotool already installed"

reset_case
NO_MANAGER_BIN="$TEMP_DIR/no-manager"
rm -rf "$NO_MANAGER_BIN"
mkdir "$NO_MANAGER_BIN"
cp "$BIN_DIR/uname" "$NO_MANAGER_BIN/uname"
cat > "$NO_MANAGER_BIN/id" << 'EOF'
#!/bin/bash
echo 1000
EOF
chmod +x "$NO_MANAGER_BIN"/*
output=$(BASH_ENV="$TEMP_DIR/missing-installer-xdotool.sh" MOCK_MANAGER=none HOME="$HOME_DIR" PATH="$NO_MANAGER_BIN:/usr/bin:/bin" MOCK_PLATFORM=Linux /usr/bin/bash "$ROOT/install.sh" 2>&1 || true)
assert_contains "$output" "No supported package manager found"

reset_case
mkdir -p "$HOME_DIR/.local/bin"
touch "$HOME_DIR/.local/bin/stay-active" "$HOME_DIR/.local/.stay_active_log"
MOCK_PLATFORM=Linux HOME="$HOME_DIR" PATH="$BIN_DIR:$PATH" "$ROOT/uninstall.sh" > /dev/null
[ ! -e "$HOME_DIR/.local/bin/stay-active" ] || fail "uninstaller did not remove the executable"
[ ! -e "$HOME_DIR/.local/.stay_active_log" ] || fail "uninstaller did not remove the log"

for script in "$ROOT/stay-active" "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/tests/run.sh"; do
    /usr/bin/bash -n "$script"
done

echo "All tests passed"
