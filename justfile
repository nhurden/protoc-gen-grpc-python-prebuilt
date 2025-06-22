lint:
    uvx ruff check

test:
    act push --job build --container-architecture linux/amd64 --matrix platform:linux-x86_64