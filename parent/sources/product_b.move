module parent::product_b;

public struct ProductB has key {
    id: object::UID,
}

public fun transfer_object(obj: ProductB, receiver: address) {
    transfer::transfer(obj, receiver);
}