#!/system/bin/sh
# ARP Flashing Helper Script
# Usage: arp_flash_zip <zip_path> [wipe_cache=0|1] [verify=0|1]

arp_flash_zip() {
    local ZOOM_BIN="$1"
    local WIPE_CACHE_VAR="${2:-0}"
    local VERIFY_VAR="${3:-0}"

    local TMP_DIR="/tmp/arp_install_TMP"
    local UPDATER_BINARY="$TMP_DIR/META-INF/com/google/android/update-binary"
    # TWRP style
    echo "Installing zip file $ZOOM_BIN"
    
    if [ ! -f "$ZOOM_BIN" ]; then
        echo "[ARP][ERR] File not found: $ZOOM_BIN"
        return 2
    fi

    # 1. Prepare temp dir
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    # 2. Extract update-binary
    echo "[ARP] Extracting update-binary..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -o "$ZOOM_BIN" "META-INF/com/google/android/update-binary" -d "$TMP_DIR" >/dev/null
    elif command -v toybox >/dev/null 2>&1; then
        toybox unzip -o "$ZOOM_BIN" "META-INF/com/google/android/update-binary" -d "$TMP_DIR" >/dev/null
    elif command -v busybox >/dev/null 2>&1; then
        busybox unzip -o "$ZOOM_BIN" "META-INF/com/google/android/update-binary" -d "$TMP_DIR" >/dev/null
    else
        echo "[ARP][ERR] No unzip tool found."
        return 3
    fi

    if [ ! -f "$UPDATER_BINARY" ]; then
        echo "[ARP][ERR] update-binary not found in zip."
        return 4
    fi
    chmod 755 "$UPDATER_BINARY"

    # 3. Execute update-binary with pipe directly via FD 1
    # We pipe stdout into a loop to parse commands.
    local UPDATER_STATUS=0
    
    # Run update-binary, passing '1' as the "pipe FD". 
    # This means update-binary will print "ui_print ..." directly to stdout.
    # We catch that stdout in the 'while' loop.
    "$UPDATER_BINARY" 3 1 "$ZOOM_BIN" | while IFS= read -r line; do
        # Strip trailing CR if any
        line="${line%%$'\r'}"
        
        # Check command prefix
        case "$line" in
            ui_print*)
                # Remove "ui_print " prefix. 
                # Note: "ui_print " might be followed by nothing (empty line)
                msg="${line#ui_print }"
                if [ "$msg" = "$line" ]; then
                    # No space after ui_print? 
                    msg="${line#ui_print}"
                fi
                echo -n "$msg"
                ;;
            progress*)
                # MVP: Ignoring progress commands for now
                ;;
            set_progress*)
                ;;
            wipe_cache*)
                echo "[ARP] wipe_cache requested"
                ;;
            log*)
                msg="${line#log }"
                echo "[LOG] $msg"
                ;;
            clear_display*)
                ;;
            minzip:*|unzip:*)
                # Magisk sometimes prints errors directly
                echo "$line"
                ;;
            *)
                # Unknown command or raw output. 
                # Print it so we see errors.
                echo "$line"
                ;;
        esac
    done
    
    local PIPE_RC=$?
    
    rm -rf "$TMP_DIR"
    echo "[ARP] Flash complete. (Pipe RC=$PIPE_RC)"
    return $PIPE_RC
}
