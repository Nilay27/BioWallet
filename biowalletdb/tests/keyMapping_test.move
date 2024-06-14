module biowalletdb::key_mapping_tests {
    use 0x1::Test;
    use 0x1::String;
    use 0x1::TxContext;
    use biowalletdb::key_mapping::{GenericTable, User, create, add, remove};

    // Test creating a new GenericTable
    public fun test_create_table(ctx: &mut TxContext) {
        let table: GenericTable<u64, String> = create<u64, String>(ctx);
        Test::assert(!table.table_values.contains_key(&1), 100, "Table should be empty upon creation");
    }

    // Test adding a key-value pair to the GenericTable
    public fun test_add_key_value(ctx: &mut TxContext) {
        let mut table: GenericTable<u64, String> = create<u64, String>(ctx);
        add(&mut table, 1, String::utf8(b"TestValue"));
        let value = table.table_values.get(&1).expect("Value should be present in table");
        Test::assert(value == String::utf8(b"TestValue"), 101, "Value should be TestValue");
    }

    // Test removing a key-value pair from the GenericTable
    public fun test_remove_key_value(ctx: &mut TxContext) {
        let mut table: GenericTable<u64, String> = create<u64, String>(ctx);
        add(&mut table, 1, String::utf8(b"TestValue"));
        let removed_value = remove(&mut table, 1);
        Test::assert(removed_value == String::utf8(b"TestValue"), 102, "Removed value should be TestValue");
        Test::assert(!table.table_values.contains_key(&1), 103, "Key should be removed from table");
    }

    // Test adding and removing a User struct
    public fun test_add_remove_user(ctx: &mut TxContext) {
        let mut table: GenericTable<String, User> = create<String, User>(ctx);
        let user = User { uniqueId: String::utf8(b"User1"), publicKey: String::utf8(b"PublicKey1") };
        add(&mut table, String::utf8(b"User1Key"), user);
        let value = table.table_values.get(&String::utf8(b"User1Key")).expect("User should be present in table");
        Test::assert(value.uniqueId == String::utf8(b"User1"), 104, "User uniqueId should be User1");
        Test::assert(value.publicKey == String::utf8(b"PublicKey1"), 105, "User publicKey should be PublicKey1");

        let removed_user = remove(&mut table, String::utf8(b"User1Key"));
        Test::assert(removed_user.uniqueId == String::utf8(b"User1"), 106, "Removed User uniqueId should be User1");
        Test::assert(removed_user.publicKey == String::utf8(b"PublicKey1"), 107, "Removed User publicKey should be PublicKey1");
        Test::assert(!table.table_values.contains_key(&String::utf8(b"User1Key")), 108, "User key should be removed from table");
    }
}
