#!/bin/bash
# opp-fbc.sh — FBC (File-Based Catalog) support functions for opp.sh
#
# These functions extend the community-operators-pipeline CI to handle
# operators that opt into the FBC workflow (fbc.enabled: true in ci.yaml).
# They are sourced by opp.sh and called during the orange (release) stage
# when OPP_PRODUCTION_TYPE is "k8s".
#
# Design mirrors community-operators-prod:
#   operators/<name>/ci.yaml            fbc.enabled + catalog_mapping
#   operators/<name>/catalog-templates/ olm.template.basic or olm.semver files
#   catalogs/latest/<name>/catalog.yaml rendered output (committed to repo)
#
# The rendered catalogs/latest/ tree is built into the catalog image via
# catalog.Dockerfile (opm serve /configs), replacing the upstream-registry-builder
# SQLite path for FBC-enabled operators.

OPP_FBC_OPM_VERSION=${OPP_FBC_OPM_VERSION-"v1.46.0"}
OPP_FBC_YQ_VERSION=${OPP_FBC_YQ_VERSION-"v4.45.1"}
OPP_FBC_RENDER_SCRIPT_URL=${OPP_FBC_RENDER_SCRIPT_URL-"https://raw.githubusercontent.com/redhat-openshift-ecosystem/operator-pipelines/main/fbc/render_catalogs.sh"}
OPP_FBC_BIN_DIR=${OPP_FBC_BIN_DIR-"/tmp/opp-fbc-bin"}
OPP_FBC_CATALOG_DIR=${OPP_FBC_CATALOG_DIR-"catalogs/latest"}

# opp_fbc_is_enabled <operator_dir>
# Returns 0 (true) if the operator at $1 has fbc.enabled: true in ci.yaml.
function opp_fbc_is_enabled() {
    local op_dir="$1"
    local ci_yaml="$op_dir/ci.yaml"
    [ -f "$ci_yaml" ] || return 1
    local enabled
    enabled=$(command -v yq &>/dev/null && yq '.fbc.enabled // false' "$ci_yaml" 2>/dev/null \
              || python3 -c "import sys,yaml; d=yaml.safe_load(open('$ci_yaml')); print(d.get('fbc',{}).get('enabled',False))" 2>/dev/null \
              || echo "false")
    [ "$enabled" = "true" ]
}

# opp_fbc_install_tools
# Downloads opm and yq into OPP_FBC_BIN_DIR if not already present.
function opp_fbc_install_tools() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m | sed 's/x86_64/amd64/')
    mkdir -p "$OPP_FBC_BIN_DIR"

    if [ ! -x "$OPP_FBC_BIN_DIR/opm" ]; then
        echo "[fbc] Downloading opm ${OPP_FBC_OPM_VERSION}..."
        curl -sLo "$OPP_FBC_BIN_DIR/opm" \
            "https://github.com/operator-framework/operator-registry/releases/download/${OPP_FBC_OPM_VERSION}/${os}-${arch}-opm"
        chmod +x "$OPP_FBC_BIN_DIR/opm"
    fi

    if [ ! -x "$OPP_FBC_BIN_DIR/yq" ]; then
        echo "[fbc] Downloading yq ${OPP_FBC_YQ_VERSION}..."
        curl -sLo "$OPP_FBC_BIN_DIR/yq" \
            "https://github.com/mikefarah/yq/releases/download/${OPP_FBC_YQ_VERSION}/yq_${os}_${arch}"
        chmod +x "$OPP_FBC_BIN_DIR/yq"
    fi

    if [ ! -x "$OPP_FBC_BIN_DIR/render_catalogs.sh" ]; then
        echo "[fbc] Downloading render_catalogs.sh..."
        curl -sLo "$OPP_FBC_BIN_DIR/render_catalogs.sh" "$OPP_FBC_RENDER_SCRIPT_URL"
        chmod +x "$OPP_FBC_BIN_DIR/render_catalogs.sh"
    fi

    export PATH="$OPP_FBC_BIN_DIR:$PATH"
}

# opp_fbc_render_catalogs <repo_root> <operator_name>
# Renders catalog-templates/ into catalogs/latest/<operator>/catalog.yaml.
# Must be called from the repository root.
function opp_fbc_render_catalogs() {
    local repo_root="$1"
    local operator_name="$2"
    local op_dir="$repo_root/operators/$operator_name"

    echo "[fbc] Rendering catalogs for $operator_name..."
    (cd "$op_dir" && TOPDIR="$repo_root" bash "$OPP_FBC_BIN_DIR/render_catalogs.sh")
    local rc=$?
    if [ $rc -ne 0 ]; then
        echo "[fbc] ERROR: render_catalogs.sh failed for $operator_name (exit $rc)"
        return $rc
    fi
    echo "[fbc] Rendered: $repo_root/$OPP_FBC_CATALOG_DIR/$operator_name/catalog.yaml"
}

# opp_fbc_validate <repo_root> <operator_name>
# Runs opm validate on the rendered catalog for the operator.
function opp_fbc_validate() {
    local repo_root="$1"
    local operator_name="$2"
    local catalog_path="$repo_root/$OPP_FBC_CATALOG_DIR/$operator_name"

    if [ ! -d "$catalog_path" ]; then
        echo "[fbc] ERROR: catalog path not found: $catalog_path"
        return 1
    fi

    echo "[fbc] Validating $catalog_path..."
    "$OPP_FBC_BIN_DIR/opm" validate "$catalog_path"
    local rc=$?
    if [ $rc -ne 0 ]; then
        echo "[fbc] ERROR: opm validate failed for $operator_name"
        return $rc
    fi
    echo "[fbc] ✅ Validation passed: $operator_name"
}

# opp_fbc_process <repo_root> <operator_name>
# Full FBC pipeline for one operator: install tools, render, validate.
# Called from opp.sh orange (release) flow when fbc.enabled: true.
function opp_fbc_process() {
    local repo_root="$1"
    local operator_name="$2"

    opp_fbc_install_tools || return 1
    opp_fbc_render_catalogs "$repo_root" "$operator_name" || return 1
    opp_fbc_validate "$repo_root" "$operator_name" || return 1
    echo "[fbc] ✅ FBC processing complete for $operator_name"
}
