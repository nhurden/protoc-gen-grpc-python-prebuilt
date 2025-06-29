# Scripts

This directory contains utility scripts for the protoc-gen-grpc-python-prebuilt repository.

## `update-versions.py`

Python script that updates the `grpc-versions.yaml` configuration by fetching the latest gRPC releases from GitHub.

**Usage:**

```bash
# Update with default settings (5 active versions)
scripts/update-versions.py

# Dry run to see what would change
scripts/update-versions.py --dry-run

# Keep 3 versions active instead of 5
scripts/update-versions.py --keep-active 3

# Fetch more releases (default is 20)
scripts/update-versions.py --limit 30
```

**What it does:**

1. Fetches the latest stable releases from GitHub API
2. Updates `grpc-versions.yaml` with new versions
3. Marks the newest N versions as active (default: 5)
4. Preserves existing version configurations
5. Sorts versions by semantic versioning
