#!/bin/bash

set -e

echo "PTB POC: Transfer Child to Parent"

# You need to manually set these package IDs after running deploy.sh
CHILD_PACKAGE="0xf2c44c07a40a4759c8a416ec43fd8216f08ee40f158b43208e06a560d0f2a03a"
PARENT_PACKAGE="0x48673a98c17bbe7946fc05f552637875fb4c6fab76fbf2738ddd162434cae8e0"

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
CHANGES=$(iota client ptb \
--assign child_object_id $CHILD_OBJECT_ID \
--assign parent_object_id $PARENT_OBJECT_ID \
--move-call $PARENT_PACKAGE::parent::borrow_child  parent_object_id child_object_id \
--assign borrowed \
--move-call $PARENT_PACKAGE::parent::get_counter parent_object_id borrowed.0 \
--assign COUNTER \
--move-call $PARENT_PACKAGE::parent::put_back parent_object_id borrowed.0 borrowed.1\
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