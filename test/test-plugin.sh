#!/bin/bash

set -euo pipefail

# Test script for protoc-gen-grpc-python plugin
# This script creates a simple test proto file and verifies the plugin works

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_PATH="$1"

if [ -z "$PLUGIN_PATH" ]; then
    echo "Usage: $0 <path-to-protoc-gen-grpc-python-plugin>"
    echo "Example: $0 ./protoc-gen-grpc-python-linux-x86_64"
    exit 1
fi

if [ ! -f "$PLUGIN_PATH" ]; then
    echo "Error: Plugin binary not found at $PLUGIN_PATH"
    exit 1
fi

if [ ! -x "$PLUGIN_PATH" ]; then
    echo "Error: Plugin binary is not executable: $PLUGIN_PATH"
    exit 1
fi

echo "Testing protoc-gen-grpc-python plugin: $PLUGIN_PATH"

# Convert to absolute path before changing directories
PLUGIN_PATH=$(realpath "$PLUGIN_PATH")
echo "Absolute plugin path: $PLUGIN_PATH"

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"

# Copy test proto file
cp "$SCRIPT_DIR/test.proto" .

echo "Step 1: Generate regular Python protobuf code"
protoc --python_out=. test.proto
if [ ! -f "test_pb2.py" ]; then
    echo "ERROR: Failed to generate test_pb2.py"
    exit 1
fi
echo "✓ Generated test_pb2.py"

echo "Step 2: Generate gRPC Python code using plugin"
protoc --plugin=protoc-gen-grpc-python="$PLUGIN_PATH" --grpc-python_out=. test.proto
if [ ! -f "test_pb2_grpc.py" ]; then
    echo "ERROR: Failed to generate test_pb2_grpc.py"
    exit 1
fi
echo "✓ Generated test_pb2_grpc.py"

echo "Step 3: Verify generated files contain expected content"

# Check protobuf file
if ! grep -q "TestService" test_pb2.py; then
    echo "ERROR: test_pb2.py doesn't contain expected service definition"
    exit 1
fi
echo "✓ test_pb2.py contains service definition"

# Check gRPC file
if ! grep -q "TestServiceServicer" test_pb2_grpc.py; then
    echo "ERROR: test_pb2_grpc.py doesn't contain expected servicer class"
    exit 1
fi

if ! grep -q "add_TestServiceServicer_to_server" test_pb2_grpc.py; then
    echo "ERROR: test_pb2_grpc.py doesn't contain expected server registration function"
    exit 1
fi

if ! grep -q "TestServiceStub" test_pb2_grpc.py; then
    echo "ERROR: test_pb2_grpc.py doesn't contain expected stub class"
    exit 1
fi
echo "✓ test_pb2_grpc.py contains expected gRPC classes"

echo "Step 4: Test Python import"
python3 -c "
import sys
sys.path.insert(0, '.')
try:
    import test_pb2
    import test_pb2_grpc
    print('✓ Python modules import successfully')
    
    # Test that gRPC classes exist
    servicer = test_pb2_grpc.TestServiceServicer()
    stub_class = test_pb2_grpc.TestServiceStub
    print('✓ gRPC classes instantiate correctly')
    
    # Test protobuf message creation
    request = test_pb2.HelloRequest(name='test')
    if request.name != 'test':
        raise Exception('Protobuf message creation failed')
    print('✓ Protobuf messages work correctly')
    
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
"

echo ""
echo "🎉 All tests passed! The protoc-gen-grpc-python plugin is working correctly."

# Clean up
rm -rf "$TEST_DIR"
echo "✓ Cleaned up test directory" 
