#[test_only]
module parent::parent_tests;

use iota::test_scenario as ts;

use parent::parent::{Self, ExampleParentObject};
use child::child_object::{Self, ExampleChildObject};

const ALICE: address = @0xA;

#[test]
/// Test creating a parent object
fun test_create_parent() {
    let mut scenario = ts::begin(ALICE);
    
    // Create parent object
    parent::create(scenario.ctx());
    
    // Verify parent was created and transferred to sender
    scenario.next_tx(ALICE);
    {
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test creating a child object
fun test_create_child() {
    let mut scenario = ts::begin(ALICE);
    
    // Create child object
    child_object::create(scenario.ctx());
    
    // Verify child was created and transferred to sender
    scenario.next_tx(ALICE);
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        assert!(child_object::get_counter(&child_obj) == 0, 0);
        scenario.return_to_sender(child_obj);
    };
    
    scenario.end();
}

#[test]
/// Test transferring child object to parent
fun test_transfer_child_to_parent() {
    let mut scenario = ts::begin(ALICE);
    
    // Step 1: Create child object
    child_object::create(scenario.ctx());
    
    // Step 2: Create parent object
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Step 3: Transfer child to parent object
    scenario.next_tx(ALICE);
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        // Transfer child to parent's address
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test receiving child and incrementing counter (matches poc.sh receive_increment_child)
fun test_receive_increment_child() {
    let mut scenario = ts::begin(ALICE);
    
    // Step 1: Create child object
    child_object::create(scenario.ctx());
    
    // Step 2: Create parent object
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Step 3: Transfer child to parent object
    scenario.next_tx(ALICE);
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // Step 4: Receive child and increment counter
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(
            ts::most_recent_id_for_address<ExampleChildObject>(object::id(&parent_obj).to_address()).extract()
        );
        
        parent::receive_increment_child(&mut parent_obj, child_receiving);
        
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test borrowing child, using it, and putting it back (matches poc.sh borrow_child flow)
fun test_borrow_child_and_put_back() {
    let mut scenario = ts::begin(ALICE);
    
    // Step 1: Create child object
    child_object::create(scenario.ctx());
    
    // Step 2: Create parent object
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Step 3: Transfer child to parent object
    scenario.next_tx(ALICE);
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // Step 4: Borrow child, get counter, and put back
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(
            ts::most_recent_id_for_address<ExampleChildObject>(object::id(&parent_obj).to_address()).extract()
        );
        
        // Borrow the child
        let (pledge, child) = parent::borrow_child(&mut parent_obj, child_receiving);
        
        // Get counter (should be 0 initially)
        let counter = child_object::get_counter(&child);
        assert!(counter == 0, 0);
        
        // Put back the child
        parent::put_back(&mut parent_obj, child, pledge);
        
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test the full flow: create, transfer, increment, borrow, verify counter
fun test_full_poc_flow() {
    let mut scenario = ts::begin(ALICE);
    
    // Step 1: Create child object
    child_object::create(scenario.ctx());
    
    // Step 2: Create parent object
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Step 3: Transfer child to parent object
    scenario.next_tx(ALICE);
    let child_id: ID;
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        child_id = object::id(&child_obj);
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // Step 4: Receive child and increment counter
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        
        parent::receive_increment_child(&mut parent_obj, child_receiving);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // Step 5: Borrow child and verify counter was incremented
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        
        // Borrow the child
        let (pledge, child) = parent::borrow_child(&mut parent_obj, child_receiving);
        
        // Verify counter was incremented to 1
        let counter = child_object::get_counter(&child);
        assert!(counter == 1, 0);
        
        // Put back the child
        parent::put_back(&mut parent_obj, child, pledge);
        
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test receiving child without incrementing
fun test_receive_child() {
    let mut scenario = ts::begin(ALICE);
    
    // Create child and parent
    child_object::create(scenario.ctx());
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Transfer child to parent
    scenario.next_tx(ALICE);
    let child_id: ID;
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        child_id = object::id(&child_obj);
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // Receive child (returns ownership)
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        
        let child = parent::receive_child(&mut parent_obj, child_receiving);
        
        // Counter should still be 0
        assert!(child_object::get_counter(&child) == 0, 0);
        
        // Transfer child back to Alice
        child_object::transfer_object(child, ALICE);
        
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

#[test]
/// Test incrementing child counter multiple times
fun test_multiple_increments() {
    let mut scenario = ts::begin(ALICE);
    
    // Create child and parent
    child_object::create(scenario.ctx());
    scenario.next_tx(ALICE);
    parent::create(scenario.ctx());
    
    // Transfer child to parent
    scenario.next_tx(ALICE);
    let child_id: ID;
    {
        let child_obj = scenario.take_from_sender<ExampleChildObject>();
        child_id = object::id(&child_obj);
        let parent_obj = scenario.take_from_sender<ExampleParentObject>();
        
        let parent_address = object::id(&parent_obj).to_address();
        child_object::transfer_object(child_obj, parent_address);
        
        scenario.return_to_sender(parent_obj);
    };
    
    // First increment
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        parent::receive_increment_child(&mut parent_obj, child_receiving);
        scenario.return_to_sender(parent_obj);
    };
    
    // Second increment
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        parent::receive_increment_child(&mut parent_obj, child_receiving);
        scenario.return_to_sender(parent_obj);
    };
    
    // Third increment
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        parent::receive_increment_child(&mut parent_obj, child_receiving);
        scenario.return_to_sender(parent_obj);
    };
    
    // Verify counter is 3
    scenario.next_tx(ALICE);
    {
        let mut parent_obj = scenario.take_from_sender<ExampleParentObject>();
        let child_receiving = ts::receiving_ticket_by_id<ExampleChildObject>(child_id);
        
        let (pledge, child) = parent::borrow_child(&mut parent_obj, child_receiving);
        assert!(child_object::get_counter(&child) == 3, 0);
        
        parent::put_back(&mut parent_obj, child, pledge);
        scenario.return_to_sender(parent_obj);
    };
    
    scenario.end();
}

