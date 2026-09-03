#!/usr/bin/env bash
# ==============================================================================
# Servio 4-Tier E2E Master Test Runner
# ==============================================================================
# Executes automated opaque-box verification across all architectural tiers:
#   Tier 1: Feature Coverage (>=5 test cases per feature)
#   Tier 2: Boundary & Corner Cases (Concurrency, Rate Limiting, UUIDs, Security)
#   Tier 3: Cross-Feature Pairwise Integration Flows
#   Tier 4: Real-World Customer & Admin Application Scenarios
#
# Usage:
#   ./e2e_tests/run_e2e.sh              # Run all tiers (1 to 4)
#   ./e2e_tests/run_e2e.sh --tier=1     # Run Tier 1 Feature Coverage
#   ./e2e_tests/run_e2e.sh --tier=2     # Run Tier 2 Boundary Cases
#   ./e2e_tests/run_e2e.sh --tier=3     # Run Tier 3 Cross-Feature Flows
#   ./e2e_tests/run_e2e.sh --tier=4     # Run Tier 4 Real-World Scenarios
#   ./e2e_tests/run_e2e.sh --verbose    # Run with verbose test outputs
#   ./e2e_tests/run_e2e.sh --live       # Force live backend execution
#   ./e2e_tests/run_e2e.sh --mock       # Force embedded mock oracle
# ==============================================================================

set -eo pipefail

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
NC="\033[0m" # No Color

# Determine project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

# Default parameters
SELECTED_TIER="all"
VERBOSE_FLAG=""
export SERVIO_E2E_MOCK="${SERVIO_E2E_MOCK:-auto}"
export SERVIO_BASE_URL="${SERVIO_BASE_URL:-http://127.0.0.1:3001}"
export FRONTEND_BASE_URL="${FRONTEND_BASE_URL:-http://127.0.0.1:5173}"

# Parse command line arguments
for arg in "$@"; do
    case "${arg}" in
        --tier=*)
            SELECTED_TIER="${arg#*=}"
            ;;
        --tier1|-t1)
            SELECTED_TIER="1"
            ;;
        --tier2|-t2)
            SELECTED_TIER="2"
            ;;
        --tier3|-t3)
            SELECTED_TIER="3"
            ;;
        --tier4|-t4)
            SELECTED_TIER="4"
            ;;
        --all)
            SELECTED_TIER="all"
            ;;
        --verbose|-v)
            VERBOSE_FLAG="-v"
            export E2E_VERBOSE="1"
            ;;
        --live)
            export SERVIO_E2E_MOCK="0"
            ;;
        --mock)
            export SERVIO_E2E_MOCK="1"
            ;;
        --help|-h)
            echo -e "${BOLD}Servio E2E Test Runner${NC}"
            echo "Options:"
            echo "  --tier=<1|2|3|4|all>   Select specific test tier"
            echo "  --verbose, -v          Verbose output for individual tests"
            echo "  --live                 Run against live server (SERVIO_BASE_URL)"
            echo "  --mock                 Run against high-fidelity mock oracle"
            echo "  --help, -h             Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: ${arg}${NC}"
            exit 2
            ;;
    esac
done

echo -e "${CYAN}${BOLD}"
echo "================================================================================"
echo "                 SERVIO E2E TEST SUITE EXECUTION RUNNER                         "
echo "================================================================================"
echo -e "${NC}"
echo -e "${BOLD}Execution Target:${NC}  ${SERVIO_BASE_URL}"
echo -e "${BOLD}Mock Oracle Mode:${NC}  ${SERVIO_E2E_MOCK}"
echo -e "${BOLD}Selected Tier:${NC}     Tier ${SELECTED_TIER}"
echo -e "${BOLD}Timestamp:${NC}         $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "--------------------------------------------------------------------------------"

START_TIME=$(python3 -c "import time; print(time.time())")
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_TIERS=()

run_tier() {
    local tier_num="$1"
    local tier_name="$2"
    local test_dir="$3"

    echo -e "\n${MAGENTA}${BOLD}[>] Running Tier ${tier_num}: ${tier_name}...${NC}"
    echo "    Directory: ${test_dir}"

    if python3 -m unittest discover ${VERBOSE_FLAG} -s "${test_dir}"; then
        echo -e "    ${GREEN}${BOLD}✓ Tier ${tier_num} PASSED${NC}"
    else
        echo -e "    ${RED}${BOLD}✗ Tier ${tier_num} FAILED${NC}"
        FAILED_TIERS+=("Tier ${tier_num}: ${tier_name}")
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        return 1
    fi
}

case "${SELECTED_TIER}" in
    1)
        run_tier "1" "Feature Coverage" "e2e_tests/tier1_feature_coverage"
        ;;
    2)
        run_tier "2" "Boundary & Concurrency" "e2e_tests/tier2_boundary_corner"
        ;;
    3)
        run_tier "3" "Cross-Feature Integration Flows" "e2e_tests/tier3_cross_feature"
        ;;
    4)
        run_tier "4" "Real-World Application Scenarios" "e2e_tests/tier4_real_world_scenarios"
        ;;
    all)
        run_tier "1" "Feature Coverage (>=5 per feature)" "e2e_tests/tier1_feature_coverage"
        run_tier "2" "Boundary & Concurrency Cases" "e2e_tests/tier2_boundary_corner"
        run_tier "3" "Cross-Feature Integration Flows" "e2e_tests/tier3_cross_feature"
        run_tier "4" "Real-World Application Scenarios" "e2e_tests/tier4_real_world_scenarios"
        ;;
    *)
        echo -e "${RED}Invalid tier specified: ${SELECTED_TIER}. Must be 1, 2, 3, 4, or all.${NC}"
        exit 2
        ;;
esac

END_TIME=$(python3 -c "import time; print(time.time())")
ELAPSED=$(python3 -c "print(f'{float(${END_TIME}) - float(${START_TIME}):.2f}')")

echo -e "\n--------------------------------------------------------------------------------"
echo -e "${CYAN}${BOLD}E2E TEST RUN SUMMARY${NC}"
echo "--------------------------------------------------------------------------------"
echo -e "${BOLD}Elapsed Time:${NC}     ${ELAPSED} seconds"

if [ ${TOTAL_FAILED} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}STATUS: ALL TEST TIERS PASSED (100% SUCCESS)${NC}"
    echo -e "${GREEN}All architectural invariants, concurrency locks, and business flows verified.${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}STATUS: FAILURES DETECTED (${TOTAL_FAILED} tier(s) failed)${NC}"
    for f in "${FAILED_TIERS[@]}"; do
        echo -e "  - ${RED}${f}${NC}"
    done
    exit 1
fi
