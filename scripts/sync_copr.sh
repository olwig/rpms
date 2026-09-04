#!/usr/bin/env bash


# TODO check all relevantze errors
# TODO incrase echos, snce is running in runner, the more the better
# TODO check that all relevant env vars are set and seem valid

set -euo pipefail

COPR_LOGIN=${COPR_LOGIN:-}
COPR_USERNAME=${COPR_USERNAME:-}
COPR_TOKEN=${COPR_TOKEN:-}
COPR_URL=${COPR_URL:-https://copr.fedorainfracloud.org}

COPR_PROJECT=${COPR_PROJECT:-onekey-wallet-bin}
COPR_OWNER=${COPR_OWNER:-olafwriggers}
COPR_PACKAGE=${COPR_PACKAGE:-onekey-wallet-bin}

GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-olwig/rpms}
GITHUB_URL=${GITHUB_URL:-https://github.com/$GITHUB_REPOSITORY.git}

DRY_RUN=${DRY_RUN:-true}

work_dir=$(mktemp -d)

repo_dir="$work_dir/repo"
copr_dir="$work_dir/copr"

mkdir -p $repo_dir
mkdir -p $copr_dir

echo "Using work dir: $work_dir"

cmds=(
    "copr-cli"
    "jq"
    "git"
)

for cmd in "${cmds[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd could not be found, please install it."
        exit 1
    fi
done

# ensure copr config exists
if [[ ! -f ~/.config/copr ]]; then
    echo "Copr config not found, creating from env's..."
    mkdir -p ~/.config
    cat > ~/.config/copr <<EOF
[copr-cli]
login = $COPR_LOGIN
username = $COPR_USERNAME
token = $COPR_TOKEN
copr_url = $COPR_URL
EOF
fi


# get package information from copr
package=
if ! package=$(copr-cli get-package --name $COPR_PACKAGE --with-latest-succeeded-build $COPR_OWNER/$COPR_PROJECT); then
    echo "Failed to get package information from copr."
    exit 1
fi

echo
echo "Package information:"
echo "--------------------"
jq . <<< "$package"

# fetch relevant information from the package JSON
build_id=$(echo $package | jq -r '.latest_succeeded_build.id')
chroot=$(echo $package | jq -r '.latest_succeeded_build.chroots[]' | grep '^fedora-[0-9]\+-x86_64$' | sort -r | head -n 1)
repo_url=$(echo $package | jq -r '.source_dict.clone_url')
_repo_spec_file=$(echo $package | jq -r '.source_dict.spec')

# be sure the repo in copr is mine
if [[ "$repo_url" != "$GITHUB_URL" ]]; then
    echo "Repo URL $repo_url does not match expected $GITHUB_URL"
    exit 1
fi

# justg get spec, clone not needed
repo_spec_file="$repo_dir/$(basename $_repo_spec_file)"
if ! curl -fsSL -o $repo_spec_file "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/$_repo_spec_file"; then
    echo "Failed to download spec file from repo."
    exit 1
fi

# downloaed spec must be present
if [[ ! -f "$repo_spec_file" ]]; then
    echo "Spec file $repo_spec_file does not exist."
    exit 1
fi


echo
echo "Build ID: $build_id"
echo "Chroot: $chroot"
echo "Repo spec file: $repo_spec_file"

# get spec from copr build
echo
copr-cli download-build --chroot $chroot --spec $build_id --dest $copr_dir
copr_spec_file="$copr_dir/$chroot/$COPR_PROJECT.spec"

echo 
echo "Comparing spec file:"
echo "--------------------------"
echo "Repo spec file: $repo_spec_file"
echo "Copr spec file: $copr_spec_file"


# compare the spec files
if diff "$repo_spec_file" "$copr_spec_file" > /dev/null; then
    echo "No changes in spec file, exiting."
    exit 0
fi
echo "Spec file changed, building package in copr..."

echo
if [[ "$DRY_RUN" != "true" ]]; then
    echo "Building package in copr ..."

    copr-cli build-package --name $COPR_PACKAGE $COPR_OWNER/$COPR_PROJECT
else
    echo "Dry run: would have built package in copr."
fi