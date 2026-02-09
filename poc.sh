#!/bin/bash

set -e

echo "PTB POC: Transfer Child to Parent"

# You need to manually set these package IDs after running deploy.sh
CHILD_PACKAGE="0x5158fbcc5b9fcaa41c7727c9fb9ee061268cab961b62c0f6f88da9e12035666d"
TF_COMPONENTS_PACKAGE="0x7d649d91b268cadfe1dc6f7c8c1769d53e448e3fb48cbdc07c76ca5bc0c13b72"
PARENT_PACKAGE="0x6576cf080cab53d1ed2af0e448777329b4871b0a9ea98b6944e8bbddd65b379f"

# Check if package IDs are set
if [ -z "$CHILD_PACKAGE" ] || [ -z "$TF_COMPONENTS_PACKAGE" ] || [ -z "$PARENT_PACKAGE" ]; then
    echo "Error: Please update CHILD_PACKAGE, TF_COMPONENTS_PACKAGE and PARENT_PACKAGE variables with actual package IDs from deploy.sh"
    exit
fi

echo "Child Package:  $CHILD_PACKAGE"
echo "TfComponents Package: $TF_COMPONENTS_PACKAGE"
echo "Parent Package: $PARENT_PACKAGE"
echo ""

# Step 1: Create child object
echo "Creating child object..."
CHILD_RESULT=$(iota client ptb --move-call $CHILD_PACKAGE::child_object::create --gas-budget 100000000 --json)
CHILD_OBJECT_ID=@$(echo "$CHILD_RESULT" | jq -r '.objectChanges[] | select(.type == "created") | .objectId' | head -1)
echo "Child Object ID: $CHILD_OBJECT_ID"

echo ""

# Step 2: Create parent object
echo "Creating parent object..."
PARENT_RESULT=$(iota client ptb --move-call $PARENT_PACKAGE::parent::create --gas-budget 100000000 --json)
PARENT_OBJECT_ID=@$(echo "$PARENT_RESULT" | jq -r '.objectChanges[] | select(.type == "created") | .objectId' | head -1)

echo "Parent Object ID: $PARENT_OBJECT_ID"

echo ""

# Step 3: Transfer child to parent object (using @ for address conversion)
echo "Transferring child object to parent..."
CHANGES=$(iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $CHILD_PACKAGE::child_object::transfer_object  child_object_id parent_object_id \
--gas-budget 100000000)

echo ""

# Step 4: Receive child from parent and increment counter
echo "Receiving child and incrementing..."
CHANGES=$(iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::request_example child_object_id \
--assign CHILD_REQUEST \
--move-call $PARENT_PACKAGE::parent::borrow_child parent_object_id CHILD_REQUEST \
--assign BORROWED_CHILD \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::extract_example BORROWED_CHILD \
--assign PLEDGE_AND_CHILD \
--move-call $CHILD_PACKAGE::child_object::increment PLEDGE_AND_CHILD.1 \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::example PLEDGE_AND_CHILD.0 PLEDGE_AND_CHILD.1 \
--assign BORROWED_CHILD \
--move-call $PARENT_PACKAGE::parent::put_back parent_object_id BORROWED_CHILD \
--gas-budget 100000000)

echo "Getting counter..."
CHANGES=$(iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::request_example child_object_id \
--assign CHILD_REQUEST \
--move-call $PARENT_PACKAGE::parent::borrow_child parent_object_id CHILD_REQUEST \
--assign BORROWED_CHILD \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::extract_example BORROWED_CHILD \
--assign PLEDGE_AND_CHILD \
--move-call $CHILD_PACKAGE::child_object::get_counter PLEDGE_AND_CHILD.1 \
--assign COUNTER \
--move-call $TF_COMPONENTS_PACKAGE::borrowed_child::example PLEDGE_AND_CHILD.0 PLEDGE_AND_CHILD.1 \
--assign BORROWED_CHILD \
--move-call $PARENT_PACKAGE::parent::put_back parent_object_id BORROWED_CHILD \
--gas-budget 100000000)

echo "Counter: $COUNTER"
echo ""

echo ""
echo "POC Complete!"
echo ""
echo "=== Object IDs ==="
echo "Child:  $CHILD_OBJECT_ID"
echo "Parent: $PARENT_OBJECT_ID"
echo ""
echo "The child object has been successfully received by the parent object."