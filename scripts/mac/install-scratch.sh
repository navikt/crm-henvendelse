#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/../..

# Check exit code function
error() {
    echo ""
    if [[ $1 -eq 0 ]]; then
        echo "Installation completed."
        echo ""
        exit $1
    else
        if [[ -n $2 ]]; then
            echo "$2"
            echo ""
        fi

        echo "Installation failed."
        echo ""
        exit $1
    fi
}

cleaningPreviousScratchOrg() {
    sf org delete scratch --no-prompt --target-org $org_alias &> /dev/null
}

creatingScratchOrg () {
    echo ""
    echo "Org Alias: $org_alias"
    echo ""

    if [[ -n $npm_config_org_duration ]]; then
        days=$npm_config_org_duration
    else
        days=30
    fi

    echo "Scratch org duration: $days days"
    sf org create scratch --set-default --definition-file config/project-scratch-def.json --duration-days "$days" --alias $org_alias || { error $? '"sf org create scratch" command failed.'; }
}

installDependencies() {
    keys=""
    for p in $(jq '.packageAliases | keys[]' sfdx-project.json -r);
    do
        # Packages listed as false in packageKeyConfig are unprotected and must be
        # installed without a key - passing one makes the install fail.
        requiresKey=$(jq --arg p "$p" 'if .packageKeyConfig[$p] == false then false else true end' sfdx-project.json)
        if [[ "$requiresKey" == "true" ]]; then
            keys+=$p":"$secret" ";
        fi
    done
    sf dependency install --installationkeys "${keys}" --targetusername "$org_alias" --targetdevhubusername "$devHubAlias" || { error $? '"sf dependency install" command failed.'; }
}

deployingMetadata() {
    if [[ $npm_config_without_deploy ]]; then
        echo "Skipping..."
    else
        sf project deploy start || { error $? '"sf project deploy start" command failed.'; }
    fi
}

#!Change this depending on your repo.
assignPermission() {
    sf project deploy start --source-dir force-app/scratch-org/permissionsets || { error $? '"sf project deploy start" (permissionsets) command failed.'; }

    for permset in $(jq '.permsets_to_assign[]' config/ssdx-config.json -r);
    do
        sf org assign permset --name "$permset" --target-org "$org_alias" || { error $? "\"sf org assign permset\" failed for $permset."; }
    done
}

#!Change this depending on your repo.
insertingTestData() {
    sf data import tree --plan dummy-data/henvendelse-data/plan.json --target-org "$org_alias" || { error $? '"sf data import tree" command failed.'; }

    npm run scratch:user:enableDebug || { error $? '"npm run scratch:user:enableDebug" command failed.'; }
    npm run scratch:enableMock:200 || { error $? '"npm run scratch:enableMock:200" command failed.'; }

    # MergeAccounts must run before GenerateData - it cleans up duplicate accounts
    # created by the tree import above.
    sf apex run --file dummy-data/MergeAccounts.apex --target-org "$org_alias" || { error $? '"sf apex run" (MergeAccounts) command failed.'; }
    sf apex run --file dummy-data/GenerateData.apex --target-org "$org_alias" || { error $? '"sf apex run" (GenerateData) command failed.'; }
    sf apex run --file dummy-data/GenerateDataThread.apex --target-org "$org_alias" || { error $? '"sf apex run" (GenerateDataThread) command failed.'; }
}

openOrg() {
    if [[ -n $npm_config_open_in ]]; then
        sf org open --browser "$npm_config_open_in" --path "lightning/" --target-org "$org_alias" || { error $? '"sf org open" command failed.'; }
    else
        sf org open --path "lightning/" --target-org "$org_alias" || { error $? '"sf org open" command failed.'; }
    fi
}

info() {
    echo "Usage: npm run mac:build [options]"
    echo ""
    echo "Options:"
    echo "  --package-key=<key>         Package key to install - THIS IS REQUIRED"
    echo "  --org-alias=<alias>         Alias for the scratch org"
    echo "  --org-duration=<days>       Duration of the scratch org"
    echo "  --without-deploy            Skip deploy"
    echo "  --open-in=<option>          Browser where the org opens."
    echo "                              <options: chrome|edge|firefox>"
    echo "  --start-step=<step-nummer>  Start from a specific step"
    echo "  --step=<step-nummer>        Run a specific step"
    echo "                              <steps: clean=1|create=2|dependencies=3|deploy=4|permissions=5|testdata=6|open=7>"
    echo "  --info                      Show this help"
    echo ""
    exit 0
}

if [[ $npm_config_info ]]; then
    info
elif [[ -z $npm_config_package_key ]] && [[ -z $npm_config_step ]] && [[ -z $npm_config_start_step ]]; then
    echo "Package key is required."
    echo ""
    info
fi

sf version >/dev/null 2>&1 || {
    echo >&2 "\"sf cli\" is required, but it's not installed."
    echo "Follow the instruction here to install it: https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm"
    echo ""
    echo "Aborting...."
    echo ""
    exit 1
}

sf plugins inspect @dxatscale/sfpowerscripts >/dev/null 2>&1 || {
    echo >&2 "\"@dxatscale/sfpowerscripts\" is required, but it's not installed."
    echo "Run \"sf plugins install @dxatscale/sfpowerscripts\" to install it."
    echo ""
    echo "Aborting...."
    echo ""
    exit 1
}

command -v jq >/dev/null 2>&1 || {
    echo >&2 "\"jq\" is required, but it's not installed."
    echo "Run \"brew install jq\" to install it if you have Homebrew installed."
    echo ""
    echo "Aborting..."
    echo ""
    exit 1
}

#!Change this depending on your repo
ORG_ALIAS="crm-henvendelse"
secret=$npm_config_package_key
devHubAlias=$(sf config get target-dev-hub --json | jq -r '.result[0].value')

if [[ -n $npm_config_org_alias ]]; then
    org_alias=$npm_config_org_alias
else
    org_alias=$ORG_ALIAS
fi

echo "Installing crm-henvendelse scratch org ($ORG_ALIAS)"
echo ""

operations=(
    cleaningPreviousScratchOrg
    creatingScratchOrg
    installDependencies
    deployingMetadata
    assignPermission
    insertingTestData
    openOrg
)

operationNames=(
    "Cleaning previous scratch org"
    "Creating scratch org"
    "Installing dependencies"
    "Deploying/Pushing metadata"
    "Assigning permissions"
    "Inserting test data"
    "Opening org"
)

if  [[ -n $npm_config_step ]] && [[ -z $npm_config_start_step ]]; then
    if [[ "$npm_config_step" =~ ^[0-9]+$ ]] && [[ $npm_config_step -ge 1 ]]; then
        j=$((npm_config_step - 1))
    else
        echo "Invalid step number: $npm_config_step"
        exit 1
    fi

    echo "Running Step $npm_config_step/${#operations[@]}: ${operationNames[$j]}..."
    ${operations[$j]}
    echo ""
    exit 0
fi

for i in ${!operations[@]}; do
    echo "Step $((i+1))/${#operations[@]}: ${operationNames[$i]}..."
    if [[ $((i+1)) -ge $npm_config_start_step ]]; then
        ${operations[$i]}
    else
        echo "Skipping..."
    fi

    echo ""
done

error $?
