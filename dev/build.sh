#!/bin/bash

#!/bin/bash

pkg_name=onekey-wallet-bin
fedora_version=44
container_name=fedora-local

build_image=${BUILD_IMAGE:-"false"}

echo "build_image: $build_image"

if [ "$build_image" = "true" ]; then
    podman build \
        --build-arg FEDORA_VERSION=$fedora_version \
        -t $container_name \
        -f dev/Containerfile
fi

if [ -n "$FISH_VERSION" ] || [ "$(basename "$SHELL")" = "fish" ]; then
    fish_history_file="dev/.fish/fish_history"
    if [ ! -f "$fish_history_file" ]; then
        mkdir -p "$(dirname "$fish_history_file")"
        touch "$fish_history_file"
    fi
    history_mount="-v ./dev/.fish/fish_history:/root/.local/share/fish/fish_history:Z"
else
    history_mount=""
fi

# mock needs elevated privileges to run in container
with_mock="--privileged --security-opt seccomp=unconfined"

# ensure host as binfmt support for qemu-user-static
# TODO check for specific arches
if ! ls /proc/sys/fs/binfmt_misc/ | grep -q qemu; then
    echo "qemu-user-static support not found on host, please install it"
    exit 1
fi

podman run -it --rm  \
    -w /work \
    -v .:/work:Z \
    $with_mock \
    $history_mount \
    --hostname "fedora-$fedora_version" \
    localhost/$container_name  #\
    #make -f .copr/Makefile srpm rpm outdir=/work/out spec=/work/dev/onekey-wallet.spec