#!/usr/bin/env bash
#===============================================================================
# Script: run_openlane.sh
# Description: Wrapper to run OpenLane 2 commands using local Nix dev shell
# Project: HMS_Timer (Hour-Minute-Second Timer IP Core)
#===============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENLANE_DIR="/home/ngobinh/openlane2"
CONFIG_FILE="${PROJECT_ROOT}/openlane/config.yaml"

MODE="${1:-synth}"
shift || true

case "$MODE" in
    synth|--synth)
        echo "================================================================="
        echo ">>> Running OpenLane 2 Logic Synthesis for HMS_Timer... <<<"
        echo "================================================================="
        cd "${PROJECT_ROOT}"
        nix develop "${OPENLANE_DIR}" --command openlane \
            --to Checker.NetlistAssignStatements \
            "${CONFIG_FILE}" "$@"
        ;;
    flow|--flow)
        echo "================================================================="
        echo ">>> Running Full OpenLane 2 ASIC Flow (RTL -> GDSII)... <<<"
        echo "================================================================="
        cd "${PROJECT_ROOT}"
        nix develop "${OPENLANE_DIR}" --command openlane \
            "${CONFIG_FILE}" "$@"
        ;;
    shell|--shell)
        echo ">>> Entering OpenLane 2 Nix Developer Shell... <<<"
        cd "${PROJECT_ROOT}"
        nix develop "${OPENLANE_DIR}"
        ;;
    *)
        # Passthrough to openlane CLI
        cd "${PROJECT_ROOT}"
        nix develop "${OPENLANE_DIR}" --command openlane "$MODE" "$@"
        ;;
esac
