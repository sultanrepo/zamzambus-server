TO insert Buses then follow the below steps.

First insert a record into the users table (since bus_owners.user_id references it).

Then insert a record into the bus_owners table referencing the users.id.

Finally, insert into the buses table with owner_id set to the bus_owners.id.

Insert -> users -> bus_owners -> buses