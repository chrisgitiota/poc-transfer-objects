module parent::product_a;

public struct ProductA has key {
    id: object::UID,
}

public fun transfer_object(obj: ProductA, receiver: address) {
    transfer::transfer(obj, receiver);
}