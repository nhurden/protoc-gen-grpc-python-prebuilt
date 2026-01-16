# protoc-gen-grpc-python-prebuilt

This repository builds and publishes prebuilt versions of the
`protoc-gen-grpc-python` plugin, addressing [gRPC issue #26125](https://github.com/grpc/grpc/issues/26125) where the plugin is not
distributed with `grpcio-tools`.

## Problem

The gRPC Python plugin (`grpc_python_plugin`) is not available as a prebuilt binary, forcing users to either:

1. Build it from source
2. Use non-standard Python-specific code generation instead of protoc plugins

This makes it impossible for tools like `buf` to (locally) generate Python
gRPC code, as they require protoc plugins.

## Usage

### Download Prebuilt Binary

1. Go to the [Releases](https://github.com/nhurden/protoc-gen-grpc-python-prebuilt/releases) page
2. Download the appropriate binary for your platform and gRPC version
3. Make it executable: `chmod +x protoc-gen-grpc-python`
4. Place it in your PATH or specify its location to protoc

### Using with protoc

```bash
protoc --plugin=protoc-gen-grpc-python=/path/to/protoc-gen-grpc-python \
       --grpc-python_out=. \
       your_service.proto
```

### Using with buf

Add to your `buf.gen.yaml`:

```yaml
version: v1
plugins:
  - name: python
    out: gen
  - name: grpc-python
    path: /path/to/protoc-gen-grpc-python
    out: gen
```

## Supported Platforms

- Linux x86_64 (amd64)
- Linux aarch64 (arm64)
- macOS x86_64 (Intel)
- macOS arm64 (Apple Silicon)

Windows is currently not supported due to the grpc repository having filenames that are too long for Windows.

## Supported gRPC Versions

See the [Releases](https://github.com/nhurden/protoc-gen-grpc-python-prebuilt/releases) page for available versions.

## Contributing

Feel free to open issues or pull requests to:

- Add support for additional platforms
- Request specific gRPC versions
- Report bugs or issues with the prebuilt binaries

## License

This repository's build scripts are licensed under MIT.

The `protoc-gen-grpc-python` binary is built from gRPC source code and is subject to the Apache 2.0 license.
