act-platform := "ubuntu-24.04=catthehacker/ubuntu:act-24.04"

lint:
    uvx ruff check
    shellcheck **/*.sh

# Generate the build matrix
test-ci-prepare:
    act push \
        --job prepare \
        -P {{act-platform}} \
        --container-architecture linux/amd64

# Run the CI lint jobs
test-ci-lint:
    act push \
        --job ruff \
        --job shellcheck \
        -P {{act-platform}} \
        --container-architecture linux/amd64

# act push doesn't work due to the dynamic matrix, so it's not included here:
# - https://github.com/nhurden/protoc-gen-grpc-python-prebuilt/issues/27
# - https://github.com/nektos/act/issues/1482
# - https://github.com/nektos/act/issues/2447

test-ci: test-ci-prepare test-ci-lint
