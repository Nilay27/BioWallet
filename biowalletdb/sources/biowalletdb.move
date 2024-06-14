module biowalletdb::biowalletdb {
    use sui::random::{Random, RandomGenerator};
    use sui::object::UID;
    use std::string::String;
    use sui::tx_context::{TxContext};
    use sui::object;
    use sui::event;
    use sui::table::{Self, Table};
    use sui::transfer;



    // Define the object struct
    public struct RandomUIDObject has copy, drop, store  {
        uid: vector<u8>,
    }

    public struct User has copy, drop, store{
        uid: String,
        public_key: String,
    }

    public struct UserMapping has key {
        id : UID,
        users: Table<String, User>
    }

    public fun create(ctx: &mut TxContext){
        let user_mapping = UserMapping{
            id: object::new(ctx),
            users: table::new(ctx),
        };
        transfer::share_object(user_mapping);
    }

    public  fun getRandonUID(r: &Random, ctx: &mut TxContext){
        let mut generator = r.new_generator(ctx);
        let uid = generator.generate_bytes(16);
        event::emit(RandomUIDObject {uid: uid})
    }

     // Function to store a vector UID corresponding to a username and public key
    public fun storeUser(username: String, public_key: String, uid: String, user_mapping: &mut UserMapping) {
        let user = User { uid: uid, public_key: public_key };
        table::add(&mut user_mapping.users, username, user);
    }

     // Function to emit the user data corresponding to the username
    public fun getUser(username: String, user_mapping: &UserMapping) {
        let user = table::borrow(&user_mapping.users, username);
        event::emit(User{uid: user.uid, public_key: user.public_key});
    }

}
