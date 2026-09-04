#!/usr/bin/env bash

COPR_LOGIN=${COPR_LOGIN:-$1}
COPR_USERNAME=${COPR_USERNAME:-$1}
COPR_TOKEN=${COPR_TOKEN:-$2}
COPR_URL=${COPR_URL:-https://copr.fedorainfracloud.org}

COPR_PROJECT=${COPR_PROJECT:-onekey-wallet-bin}
COPR_OWNER=${COPR_OWNER:-olafwriggers}
COPR_PACKAGE=${COPR_PACKAGE:-onekey-wallet-bin}

GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-olwig/rpms}
GITHUB_URL=${GITHUB_URL:-https://github.com/$GITHUB_REPOSITORY.git}

DRY_RUN=${DRY_RUN:-true}

work_dir=$(mktemp -d)


work_dir=/tmp/stabletemphkg
mkdir -p $work_dir

rm -rf $work_dir/repo

repo_dir="$work_dir/repo"
copr_dir="$work_dir/copr"

mkdir -p $repo_dir
mkdir -p $copr_dir

echo "Using work dir: $work_dir"


# write ~/.config/copr if not present
if [[ ! -f ~/.config/copr ]]; then
    mkdir -p ~/.config
    cat > ~/.config/copr <<-EOF
[copr-cli]
login = $COPR_LOGIN
username = $COPR_USERNAME
token = $COPR_TOKEN
copr_url = $COPR_URL
EOF
fi

# ping with copr-cli to test connectivity

package=$(copr-cli get-package --name $COPR_PACKAGE --with-latest-succeeded-build $COPR_OWNER/$COPR_PROJECT)
build_id=$(echo $package | jq -r '.latest_succeeded_build.id')
chroot=$(echo $package | jq -r '.latest_succeeded_build.chroots[]' | grep '^fedora-[0-9]\+-x86_64$' | sort -r | head -n 1)
repo_url=$(echo $package | jq -r '.source_dict.clone_url')
_repo_spec_file=$(echo $package | jq -r '.source_dict.spec')

# besure the repo in copr is mine
if [[ "$repo_url" != "$GITHUB_URL" ]]; then
    echo "Repo URL $repo_url does not match expected $GITHUB_URL"
    exit 1
fi

#git clone $repo_url $repo_dir

repo_spec_file="$repo_dir/$(basename $_repo_spec_file)"
curl -fsSL -o $repo_spec_file "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/$_repo_spec_file"



echo "Build ID: $build_id"
echo "Chroot: $chroot"
echo "Repo spec file: $repo_spec_file"


copr-cli download-build --chroot $chroot --spec $build_id --dest $copr_dir

copr_spec_file="$copr_dir/$chroot/$COPR_PROJECT.spec"

echo "Copr spec file: $copr_spec_file"

#echo "amek diff" >> $copr_spec_file


# compare the spec files
diff=$(diff $repo_spec_file $copr_spec_file)
if [[ $? -eq 0 && -z "$diff" ]]; then
    echo "No changes in spec file, exiting."
    exit 0
fi
echo "Spec file changed, building package in copr..."

if [[ "$DRY_RUN" != "true" ]]; then
    copr-cli build-package --name $COPR_PACKAGE $COPR_OWNER/$COPR_PROJECT
else
    echo "Dry run: would have built package in copr."
fi