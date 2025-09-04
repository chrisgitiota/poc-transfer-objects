#!/bin/bash

set -e

echo "PTB POC: Transfer Child to Parent"

# You need to manually set these package IDs after running deploy.sh
CHILD_PACKAGE="0x0bfdb08caa2c1c77a840c4b78f29afd419203e498f6e83e4c8ebaf56a721f26a"
PARENT_PACKAGE="0x34706e00a71fa0abf48b2a918721d8028b218c97b2f120dd2fade661b507dfcd"

# Check if package IDs are set
if [ -z "$CHILD_PACKAGE" ] || [ -z "$PARENT_PACKAGE" ]; then
    echo "Error: Please update CHILD_PACKAGE and PARENT_PACKAGE variables with actual package IDs from deploy.sh"
    exit 1
fi

echo "Child Package:  $CHILD_PACKAGE"
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
iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $CHILD_PACKAGE::child_object::transfer_object  child_object_id parent_object_id \
--gas-budget 100000000

echo ""

# Step 4: Receive child object into parent
echo "Receiving child and incrementing..."
iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $PARENT_PACKAGE::parent::receive_increment_child parent_object_id child_object_id \
--gas-budget 100000000

echo "Getting counter..."
COUNTER=$(iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $PARENT_PACKAGE::parent::receive_child  parent_object_id child_object_id \
--assign received_object \
--move-call $PARENT_PACKAGE::parent::get_counter parent_object_id received_object \
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