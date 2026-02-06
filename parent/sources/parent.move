/*
/// Module: parent
module parent::parent;
*/

// For Move coding conventions, see
// https://docs.iota.org/developer/iota-101/move-overview/conventions
module parent::parent;

use child::child_object::{ExampleChildObject};
use iota::transfer::Receiving;
use parent::borrowed_child::{Self, Pledge};

// ------------------------------------------------------------------------------------

public struct ExampleParentObject has key {
    id: object::UID,
}

public fun create(ctx: &mut TxContext) {
    let s = ExampleParentObject {
        id: object::new(ctx),
    };
    transfer::transfer(s, ctx.sender());
}

public fun receive_increment_child(
    obj: &mut ExampleParentObject,
    r: Receiving<ExampleChildObject>,
) {
    let mut c = child::child_object::receive(&mut obj.id, r);
    child::child_object::increment(&mut c);
    child::child_object::transfer_object(c, obj.id.to_address());
}

public fun receive_child(
    obj: &mut ExampleParentObject,
    receiver: Receiving<ExampleChildObject>,
): ExampleChildObject {
    child::child_object::receive(&mut obj.id, receiver)
}

public fun borrow_child(
    obj: &mut ExampleParentObject,
    receiver: Receiving<ExampleChildObject>,
): (Pledge, ExampleChildObject) {
    let (pledge, borrowed) = borrowed_child::borrow(&mut obj.id, borrowed_child::request_example(receiver));
    let child = borrowed.extract_example();
    (pledge, child)
}

public fun put_back(parent_object: &mut ExampleParentObject, child: ExampleChildObject, pledge: Pledge) {
    borrowed_child::put_back(parent_object.id.as_inner(), borrowed_child::example(child), pledge);
}

// public fun get_counter(parent_object: &mut ExampleParentObject, obj: &ExampleChildObject): u64 {
//     let counter = child::child_object::get_counter(obj);
//     // child::child_object::transfer_object(obj, parent_object.id.to_address());
//     counter
// }
