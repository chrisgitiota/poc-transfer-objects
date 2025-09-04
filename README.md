## IOTA Move POC — Receiving Child Objects in a Parent

This proof-of-concept demonstrates how to transfer an owned object (the “child”) to a parent address and then safely “receive” it inside a different module using IOTA Move’s `Receiving<T>` pattern. It also shows how to mutate the received child and return it back to the parent’s address.

### What this POC shows

- **Creating** a child object (`child::child_object::create`).
- **Creating** a parent object (`parent::parent::create`).
- **Transferring** the child object to the parent’s address (`child::child_object::transfer_object`).
- **Receiving** the child inside the parent module (`parent::parent::receive_child` / `receive_increment_child`) via `Receiving<ExampleChildObject>`.
- **Mutating** the child (increment a counter) and sending it back to the parent’s address.

---

## Quick start

1) Make scripts executable

```bash
chmod +x deploy.sh poc.sh
```

2) Build and publish both packages

```bash
./deploy.sh
```

The script prints two IDs:

- `Child Package ID: <0x...>`
- `Parent Package ID: <0x...>`

3) Update `poc.sh`
Open `poc.sh` and set:

```bash
CHILD_PACKAGE="0x..."
PARENT_PACKAGE="0x..."
```

Use the IDs printed by `deploy.sh`.

4) Run the POC

```bash
./poc.sh
```

You should see logs for creating objects, transferring the child, receiving + incrementing, and finally a printed counter value.

---

## What `poc.sh` does (step-by-step)

The script drives a single PTB-based flow:

1) **Create the child**
   - Calls `child::child_object::create` to mint an `ExampleChildObject` to your sender address.
   - Captures the new child’s `objectId` from JSON output.

2) **Create the parent**
   - Calls `parent::parent::create` to mint an `ExampleParentObject` to your sender address.
   - Captures the parent’s `objectId`.

3) **Transfer the child to the parent’s address**
   - Calls `child::child_object::transfer_object(child, parent_addr)`.
   - The script passes the child `objectId` and the parent `objectId` (treated as an address). The `@` prefix in CLI args indicates an object ID/address literal.

4) **Receive and increment the child inside the parent**
   - Calls `parent::parent::receive_increment_child(&mut parent, Receiving<ExampleChildObject>)`.
   - Inside the function, the parent uses `child::child_object::receive(&mut parent.id, r)` to take custody of the child, increments it, then transfers it back to the parent’s address.

5) **Read the counter**
   - The script chains two PTB calls:
     - `receive_child(&mut parent, Receiving<ExampleChildObject>) -> ExampleChildObject` to materialize the child into the PTB pipeline.
     - `get_counter(&mut parent, obj) -> u64` to read the counter and then return the child to the parent’s address.
   - The final printed value is the child’s counter after the increment.

---

## How the receiving pattern works

- The `Receiving<T>` type represents a to-be-received object that was transferred to an address but not yet materialized under a specific object’s authority.
- The parent completes the receive with `child::child_object::receive(&mut parent.id, r)` which checks the receiver and returns an `ExampleChildObject` for in-module use.
- After you’re done, you can re-transfer the child back to the parent’s address to maintain ownership consistency.

---

## Troubleshooting

- **Object not found / wrong object type**: Ensure you used the correct package IDs and the latest `child` and `parent` object IDs from the creation steps.
- **Insufficient gas**: Increase `--gas-budget`.
- **CLI errors**: Verify your active address/network with `iota client switch` and ensure `jq` is installed.
