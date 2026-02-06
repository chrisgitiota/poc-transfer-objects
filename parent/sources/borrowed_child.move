module parent::borrowed_child;

use iota::transfer::Receiving;
use parent::product_a::{Self, ProductA};
use parent::product_b::{Self, ProductB};
use child::child_object::{Self, ExampleChildObject};

// ===== Errors =====
/// Error when BorrowedChild variant does not match the choosen extract function
const EBorrowedChildVariantMismatch: u64 = 0;

// ----------------------------------------------------------------------------------------------

public enum BorrowRequest {
    A(Receiving<ProductA>),
    B(Receiving<ProductB>),
    Example(Receiving<ExampleChildObject>)
}

public fun request_a(receiver: Receiving<ProductA>): BorrowRequest {
    BorrowRequest::A(receiver)
}

public fun request_b(receiver: Receiving<ProductB>): BorrowRequest {
    BorrowRequest::B(receiver)
}

public fun request_example(receiver: Receiving<ExampleChildObject>): BorrowRequest {
    BorrowRequest::Example(receiver)
}

// ----------------------------------------------------------------------------------------------

public enum BorrowedChild {
    A(ProductA),
    B(ProductB),
    Example(ExampleChildObject)
}

public fun a(child: ProductA): BorrowedChild {
    BorrowedChild::A(child)
}
public fun b(child: ProductB): BorrowedChild {
    BorrowedChild::B(child)
}
public fun example(child: ExampleChildObject): BorrowedChild {
    BorrowedChild::Example(child)
}

public fun extract_a(borrowed: BorrowedChild): ProductA {
    match (borrowed) {
        BorrowedChild::A(child) => child,
        BorrowedChild::B(_child) => abort EBorrowedChildVariantMismatch,
        BorrowedChild::Example(_child) => abort EBorrowedChildVariantMismatch,
    }
}

public fun extract_b(borrowed: BorrowedChild): ProductB {
    match (borrowed) {
        BorrowedChild::A(_child) => abort EBorrowedChildVariantMismatch,
        BorrowedChild::B(child) => child,
        BorrowedChild::Example(_child) => abort EBorrowedChildVariantMismatch,
    }
}

public fun extract_example(borrowed: BorrowedChild): ExampleChildObject {
    match (borrowed) {
        BorrowedChild::A(_child) => abort EBorrowedChildVariantMismatch,
        BorrowedChild::B(_child) => abort EBorrowedChildVariantMismatch,
        BorrowedChild::Example(child) => child,
    }
}

// ----------------------------------------------------------------------------------------------

/// A hot potato making sure the object is put back once borrowed.
public struct Pledge {
    parent: ID,
    child: ID
}

public fun pledge<C: key>(parent_id: &ID, child: &C): Pledge {
    Pledge {
        parent: *parent_id,
        child: object::id(child),
    }
}

public fun borrow(
    parent: &mut UID,
    request: BorrowRequest,
): (Pledge, BorrowedChild) {
    
    match (request) {
        BorrowRequest::A(receiver) => {
            let child = product_a::receive(parent, receiver);
            (pledge(parent.as_inner(), &child), BorrowedChild::A(child))
        },
        BorrowRequest::B(receiver) => {
            let child = product_b::receive(parent, receiver);
            (pledge(parent.as_inner(), &child), BorrowedChild::B(child))
        },
        BorrowRequest::Example(receiver) => {
            let child = child_object::receive(parent, receiver);
            (pledge(parent.as_inner(), &child), BorrowedChild::Example(child))
        },
    }
}

public fun put_back(parent_object_id: &ID, borrowed_obj: BorrowedChild, pledge: Pledge) {
    assert!(parent_object_id == pledge.parent, 1);

    match (borrowed_obj) {
        BorrowedChild::A(child) => {
            assert!(object::id(&child) == pledge.child, 2);             
            parent::product_a::transfer_object(child, parent_object_id.to_address());
        },
        BorrowedChild::B(child) => {
            assert!(object::id(&child) == pledge.child, 2);             
            parent::product_b::transfer_object(child, parent_object_id.to_address());
        },
        BorrowedChild::Example(child) => {
            assert!(object::id(&child) == pledge.child, 2);
            child::child_object::transfer_object(child, parent_object_id.to_address());
        },
    };
    
    let Pledge {parent: _, child: _} = pledge;
}
