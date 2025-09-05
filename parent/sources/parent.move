/*
/// Module: parent
module parent::parent;
*/

// For Move coding conventions, see
// https://docs.iota.org/developer/iota-101/move-overview/conventions
module parent::parent;

use child::child_object::{ExampleChildObject, receive};
use iota::transfer::Receiving;
use parent::product_a::ProductA;
use parent::product_b::ProductB;

public enum BorrowedObjectType {
    A(ProductA),
    B(ProductB),
    C(ExampleChildObject)
}

/// A hot potato making sure the object is put back once borrowed.
public struct Pledge {
    parent: ID,
    child: ID
}

public fun borrow<P: key, C: key>(parent: &P, child: C): (C, Pledge) {
    let pledge = Pledge {
        parent: object::id(parent),
        child: object::id(&child)
    };
    (child, pledge)
}

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
): (ExampleChildObject, Pledge) {
    let child = child::child_object::receive(&mut obj.id, receiver);
    borrow(obj, child)
}

public fun put_back(parent_object: &mut ExampleParentObject, child: ExampleChildObject, pledge: Pledge) {
    put_back_generic(parent_object, BorrowedObjectType::C(child), pledge);
}

public fun put_back_generic(parent_object: &mut ExampleParentObject, child: BorrowedObjectType, pledge: Pledge) {
    assert!(object::id(parent_object) == pledge.parent, 1);
    match (child) {
        BorrowedObjectType::A(child) => {
            assert!(object::id(&child) == pledge.child, 2);             
            parent::product_a::transfer_object(child, parent_object.id.to_address());
        },
        BorrowedObjectType::B(child) => {
            assert!(object::id(&child) == pledge.child, 2);             
            parent::product_b::transfer_object(child, parent_object.id.to_address());
        },
        BorrowedObjectType::C(child) => {
            assert!(object::id(&child) == pledge.child, 2);
            child::child_object::transfer_object(child, parent_object.id.to_address());
        },
    };
    
    let Pledge {parent: _, child: _} = pledge;
}

public fun get_counter(parent_object: &mut ExampleParentObject, obj: &ExampleChildObject): u64 {
    let counter = child::child_object::get_counter(obj);
    // child::child_object::transfer_object(obj, parent_object.id.to_address());
    counter
}
