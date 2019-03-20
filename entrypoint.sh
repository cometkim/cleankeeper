#!/bin/bash

. /action/lib-semver.sh

set -e
set -o pipefail

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo '$GITHUB_TOKEN does not exist.'
    exit 1
fi

if [[ -z "$GITHUB_REF" ]]; then
    echo '$GITHUB_REF does not exist. Make sure to configure on available action type'
    exit 1
fi

API_URI=https://api.github.com
API_VERSION=v3
API_HEADER="Accept: application/vnd.github.${API_VERSION}+json"
AUTH_HEADER="Authorization: Token ${GITHUB_TOKEN}"

REF_FULL_REGEX='refs/heads/greenkeeper/(monorepo\.)?([-_[:alnum:]]+)-([-_\.[:digit:]]+)'

filter_action() {
    # Filter events only "merged pull requests"
    local action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
    local merged=$(jq --raw-output .pull_request.merged "$GITHUB_EVENT_PATH")

    if [[ ! "$action" == 'closed' ]] || [[ ! "$merged" == 'true' ]]; then
        exit 78 # netural
    fi
}

main() {
    if ! [[ "$GITHUB_REF" =~ $REF_FULL_REGEX ]]; then
        exit 78 # netural
    fi

    local ref_package_name="${BASH_REMATCH[2]}"
    local ref_package_version="${BASH_REMATCH[3]}"

    echo "package name: $ref_package_name"
    echo "package version: $ref_package_version"

    if semver_check "$ref_package_version"; then
        echo "Determined $ref_package_version as semver format"
    elif [[ "$ref_package_version" =~ [[:digit:]]+ ]]; then
        echo "Determined $ref_package_version as numeric format"

        # Transform numeric version to semver-like
        ref_package_version="${ref_package_version}.0.0"
    else
        echo "Only semver or numeric version format is supported"
        exit 1
    fi

    local other_refs=$(
        curl -XGET -fsSL \
            -H "${AUTH_HEADER}" \
            -H "${API_HEADER}" \
            "${API_URI}/repos/${GITHUB_REPOSITORY}/git/refs" | jq ".[].ref" | grep "$ref_package_name" \
    )

    for other_ref in $other_refs; do
        echo "Processing $other_ref..."

        # Remove quotation marks
        other_ref=${other_ref%\"}
        other_ref=${other_ref#\"}

        [[ $other_ref =~ $REF_FULL_REGEX ]] && \
        local other_ref_package_version="${BASH_REMATCH[3]}"

        if [[ "$other_ref_package_version" =~ [[:digit:]]+ ]]; then
            other_ref_package_version="${other_ref_package_version}.0.0"
        fi

        if ! semver_compare "$ref_package_version" "$other_ref_package_version"; then
            echo "Merged ref has greater version than this, deleting..."
            curl -XDELETE -sSL \
                -H "${AUTH_HEADER}" \
                -H "${API_HEADER}" \
                "${API_URI}/repos/${GITHUB_REPOSITORY}/git/${other_ref%\"}"
        fi
    done

    exit 0
}

filter_action
main "$@"
