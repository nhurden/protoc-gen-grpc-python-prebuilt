lint:
    uvx ruff check
    shellcheck **/*.sh

test-linux-amd64:
    act push --job build --matrix platform:linux-x86_64 --container-architecture linux/amd64

test: test-linux-amd64
