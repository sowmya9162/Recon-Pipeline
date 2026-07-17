#!/usr/bin/env bash
#
# recon.sh — Automated Bug Bounty Recon Pipeline (orchestrator)
#
# Chains passive recon -> active recon -> crawling -> JS/file analysis ->
# parameter mining -> automated scanning -> report scaffolding.
#
# Usage:
#   ./recon.sh -d example.com -o output/example.com
#
# WARNING: Only run against targets you are explicitly authorized to test.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMAIN=""
OUTDIR=""

usage() {
    echo "Usage: $0 -d <domain> -o <output_dir>"
    exit 1
}

while getopts "d:o:h" opt; do
    case "$opt" in
        d) DOMAIN="$OPTARG" ;;
        o) OUTDIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ -z "$DOMAIN" || -z "$OUTDIR" ]]; then
    usage
fi

mkdir -p "$OUTDIR"/{subdomains,ports,endpoints,js_analysis,params,scans,report}

echo "[*] Target: $DOMAIN"
echo "[*] Output directory: $OUTDIR"
echo "[*] Confirm this target is in-scope for testing before continuing."
read -rp "    Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "[!] Aborted."
    exit 1
fi

echo "[1/8] Passive recon..."
bash "$SCRIPT_DIR/modules/01_passive_recon.sh" "$DOMAIN" "$OUTDIR"

echo "[2/8] Active recon (DNS resolution, live host probing, port scan)..."
bash "$SCRIPT_DIR/modules/02_active_recon.sh" "$DOMAIN" "$OUTDIR"

echo "[3/8] Crawling & fingerprinting..."
bash "$SCRIPT_DIR/modules/03_crawl_and_fingerprint.sh" "$DOMAIN" "$OUTDIR"

echo "[4/8] JavaScript analysis..."
bash "$SCRIPT_DIR/modules/04_js_analysis.sh" "$DOMAIN" "$OUTDIR"

echo "[5/8] Interesting file discovery..."
bash "$SCRIPT_DIR/modules/05_interesting_files.sh" "$DOMAIN" "$OUTDIR"

echo "[6/8] Parameter mining..."
bash "$SCRIPT_DIR/modules/06_param_mining.sh" "$DOMAIN" "$OUTDIR"

echo "[7/8] Automated scanning..."
bash "$SCRIPT_DIR/modules/07_automated_scan.sh" "$DOMAIN" "$OUTDIR"

echo "[8/8] Generating report scaffold..."
bash "$SCRIPT_DIR/modules/08_report_scaffold.sh" "$DOMAIN" "$OUTDIR"

echo "[*] Done. Review results in: $OUTDIR"
echo "[*] Remember: manual validation and PoC evidence are required before reporting any finding."
