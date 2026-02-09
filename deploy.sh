#!/bin/bash

set -e

echo "Deploying IOTA Move contracts..."

# Deploy child contract first
echo "Building and deploying child contract..."
cd child
iota move build
echo "Publishing child contract..."
CHILD_RESULT=$(iota client publish --gas-budget 100000000 . --json)
CHILD_PACKAGE=$(echo "$CHILD_RESULT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
echo "Child Package ID: $CHILD_PACKAGE"
cd ..

echo ""

# Deploy tf_components as second package
echo "Building and deploying tf_components contract..."
cd tf_components
iota move build
echo "Publishing tf_components contract..."
TF_CMP_RESULT=$(iota client publish --gas-budget 100000000 . --json)
TF_CMP_PACKAGE=$(echo "$TF_CMP_RESULT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
echo "TfComponents Package ID: $TF_CMP_PACKAGE"
cd ..

echo ""

# Deploy parent contract (depends on child)
echo "Building and deploying parent contract..."
cd parent
iota move build
echo "Publishing parent contract..."
PARENT_RESULT=$(iota client publish --gas-budget 100000000 . --json)
PARENT_PACKAGE=$(echo "$PARENT_RESULT" | jq -r '.objectChanges[] | select(.type == "published") | .packageId')
echo "Parent Package ID: $PARENT_PACKAGE"
cd ..

echo ""
echo "Deployment complete!"
echo ""
echo "=== Contract Addresses ==="
echo "CHILD_PACKAGE=\"$CHILD_PACKAGE\""
echo "TF_COMPONENTS_PACKAGE=\"$TF_CMP_PACKAGE\""
echo "PARENT_PACKAGE=\"$PARENT_PACKAGE\""