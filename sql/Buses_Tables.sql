-- buses (core metadata)
--API Created for Create Bus (/api/users/create-bus_owners)
CREATE TABLE buses (
    id SERIAL PRIMARY KEY,
    bus_name VARCHAR(100) NOT NULL,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    bus_type VARCHAR(50) NOT NULL, -- e.g., 'AC Sleeper', 'AC Seater + Sleeper'
    make VARCHAR(50),
    model VARCHAR(50),
    manufacture_year INT,
    odo_meter INT,
    last_service_date DATE,
    next_service_due DATE,
    maintenance_note TEXT,

    insurance_number VARCHAR(100),
    insurance_expiry DATE,
    permit_number VARCHAR(100),
    permit_expiry DATE,

    max_luggage_kg INT DEFAULT 20,
    amenities JSONB, -- ['WiFi', 'Charging Point', etc.]
    images TEXT[], -- CDN/S3 URLs

    gps_enabled BOOLEAN DEFAULT FALSE,
    gps_device_id VARCHAR(100),

    is_active BOOLEAN DEFAULT TRUE,
    is_operational BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,

    owner_id INT REFERENCES bus_owners(id) ON DELETE SET NULL,

    average_rating FLOAT DEFAULT 0,
    total_reviews INT DEFAULT 0,

    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seats

-- Step 1: Create ENUM types
CREATE TYPE deck_type AS ENUM ('upper', 'lower');
CREATE TYPE seat_type_enum AS ENUM ('sleeper', 'seater');
CREATE TYPE orientation_enum AS ENUM ('horizontal', 'vertical');

-- Step 2: Create the table
CREATE TABLE seats (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    seat_number VARCHAR(10),
    deck deck_type NOT NULL,
    seat_type seat_type_enum NOT NULL,
    position JSONB,
    orientation orientation_enum DEFAULT 'horizontal',
    is_window BOOLEAN DEFAULT FALSE,
    fare NUMERIC(10, 2) NOT NULL,
    is_reserved BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);


-- Seats Layout
--Stores common layouts like "2x2 seater", "1x2 sleeper", etc., referenced by layout_id.

-- Step 1: Create ENUM type
CREATE TYPE layout_type_enum AS ENUM ('seater', 'sleeper', 'seater+sleeper');

-- Step 2: Create the table using the new ENUM type
CREATE TABLE seat_layouts (
    id SERIAL PRIMARY KEY,
    layout_name VARCHAR(100) UNIQUE,
    layout_type layout_type_enum,
    description TEXT,
    deck_count INT CHECK (deck_count BETWEEN 1 AND 2),
    layout_config JSONB, -- e.g., { "lower": [["S1","S2"],["S3","S4"]], "upper": [...] }
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- (optional) bus_fares (seasonal / route-specific fare overrides)
-- If fare depends on route/date/special day.
-- Not Created in DB

CREATE TABLE bus_fares (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    seat_type ENUM('sleeper', 'seater'),
    base_fare NUMERIC(10, 2),
    dynamic_fare BOOLEAN DEFAULT FALSE,
    route_id INT REFERENCES routes(id), -- if route-based
    valid_from DATE,
    valid_to DATE
);

-- 1. locations (City, stop, terminal, or pickup point)

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,       -- e.g., 'Lalit Bus Stand', 'Gopalganj More'
    city VARCHAR(100) NOT NULL,       -- e.g., 'Pune'
    state VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    is_active BOOLEAN DEFAULT TRUE,
    parent_city_id INT REFERENCES locations(id), -- points to the "main" city (e.g. Delhi)  -- New Added
);

-- 1.1. route (This table define the bus routes)
CREATE TABLE routes (
    id SERIAL PRIMARY KEY,
    route_name VARCHAR(100) NOT NULL,
    source_location_id INT REFERENCES locations(id) ON DELETE CASCADE,
    destination_location_id INT REFERENCES locations(id) ON DELETE CASCADE,
    via TEXT[],  -- Stores intermediate stops as an array {Gopalganj, Lucknow}
    status VARCHAR(20) DEFAULT 'active'  -- Example: 'active', 'inactive'
);

-- 1.2. Create Bus Trip (This table is responsible for the bus trip. If user searches for the bus, this table is main responcible to fined the bus).
CREATE TABLE bus_trips (
    id SERIAL PRIMARY KEY,
    bus_trip_code BIGINT UNIQUE NOT NULL DEFAULT nextval('bus_trip_code_seq'),
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    route_id INT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata'),
    updated_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);

Bus Trip

1. id
2. Bus Trip ID
3. Bus ID -connected to buses table (id) column
4. route ID -connected to routes Table (id) column
-- 5. Pick up locations --
-- 6. Drop locations    -- 
7. departure time
8. Arrival time
   Trip Start Date -This is because when a bus owner wants to create the trips for multiple dates like owner can create trip starts on 2025-08-15
   Trip Ends date  -This is because when a owner will select the start date then definatly he will end the trip on spesific date. 2025-08-30 (It will shows daily to the users from 15 to 30).
9. status -initially active
10. created_at -get current IST time when created
11. updated_at -get current IST time when rows updated


----------------------------------------------------------------------
-- Create states table
CREATE TABLE states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE         -- e.g., 'Bihar', 'Maharashtra'
);

-- Create cities table
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state_id INTEGER NOT NULL,
    FOREIGN KEY (state_id) REFERENCES states(id) ON DELETE CASCADE,
    UNIQUE (name, state_id)                   -- ensures no duplicate cities in the same state
);
----------------------------------------------------------------------

-- 2. bus_trips (Each scheduled run of a bus)
-- 🔁 This replaces complex route modeling with a simple trip from A → B.

CREATE TABLE bus_trips (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    source_location_id INT REFERENCES locations(id),
    destination_location_id INT REFERENCES locations(id),
    
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP,

    travel_date DATE NOT NULL, 
    -- for one-off or recurring logic 
    --✅ CASE 1: One-Time Trip (is_recurring = FALSE) travel_date = the exact date on which the bus will travel.
    --🔁 CASE 2: Recurring Trip (is_recurring = TRUE) travel_date = the date when the recurring schedule starts.

    is_recurring BOOLEAN DEFAULT FALSE,
    -- days_of_week VARCHAR(20), -- if recurring: 'Mon,Tue,Wed' ****** Earlier *****
    days_of_week TEXT[], -- normalized: ['Mon', 'Tue', 'Wed']   ****** Now Updated *****

    is_active BOOLEAN DEFAULT TRUE
);
-- Querying by Day To get recurring trips on 'Wed' And check with cancelled_trip:
SELECT *
FROM bus_trips bt
WHERE is_recurring = TRUE
  AND travel_date <= '2025-08-13'
  AND 'Wed' = ANY(bt.days_of_week)
  AND NOT EXISTS (
    SELECT 1 FROM cancelled_trip_dates ctd
    WHERE ctd.bus_trip_id = bt.id
      AND ctd.cancelled_date = '2025-08-13'
);

-- 2.1 . ✅ Solution: Use a New Table — cancelled_trip_dates You need a table to store exceptions (i.e., cancellations) for recurring trips.
-- 🗂️ New Table: cancelled_trip_dates
CREATE TABLE cancelled_trip_dates (
    id SERIAL PRIMARY KEY,
    bus_trip_id INT REFERENCES bus_trips(id) ON DELETE CASCADE,
    cancelled_date DATE NOT NULL
);

-- 3.1. pickup_points (locations where boarding is allowed for this trip)

CREATE TABLE pickup_locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,      -- "Siwan Bus Stand", "Gopalganj More"
    city VARCHAR(100) NOT NULL,      -- "Siwan"
    state VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    sort_order INT DEFAULT 0,        -- order of stops in listings
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);


-- 4.1. drop_points (locations where passengers can get off)

CREATE TABLE drop_locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,      -- "Anand Vihar ISBT", "Noida Sector 62"
    city VARCHAR(100) NOT NULL,      -- "Delhi"
    state VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    sort_order INT DEFAULT 0,        -- order of stops in listings
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);


-- 3. pickup_points (locations where boarding is allowed for this trip)

CREATE TABLE pickup_points (
    id SERIAL PRIMARY KEY,
    trip_id INT NOT NULL REFERENCES bus_trips(id) ON DELETE CASCADE,
    pickup_location_id INT NOT NULL REFERENCES pickup_locations(id) ON DELETE CASCADE,
    pickup_time TIMESTAMPTZ NOT NULL,
    sequence_no INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);


-- 4. drop_points (locations where passengers can get off)

CREATE TABLE drop_points (
    id SERIAL PRIMARY KEY,
    trip_id INT NOT NULL REFERENCES bus_trips(id) ON DELETE CASCADE,
    drop_location_id INT NOT NULL REFERENCES drop_locations(id) ON DELETE CASCADE,
    drop_time TIMESTAMPTZ NOT NULL,
    sequence_no INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')
);



-- Query to find the buses


SELECT 
    bt.id AS trip_id,
    b.bus_name,
    bt.departure_time,
    bt.arrival_time
FROM
    bus_trips bt
JOIN buses b ON b.id = bt.bus_id
JOIN locations src ON src.id = bt.source_location_id
JOIN locations dest ON dest.id = bt.destination_location_id
WHERE
    src.city = 'Pune'
    AND dest.city = 'Mumbai'
    AND bt.travel_date = '2025-07-23'
    AND bt.is_active = TRUE;

-- 🔎 “If I search from Gopalganj → Delhi, and the bus actually runs Siwan → Delhi but stops at Gopalganj, how do I still find that bus?”

--✅ Keep this DB schema:
/*🧩 bus_trips
Defines each scheduled trip:

source_location_id = Siwan

destination_location_id = Delhi

🧩 pickup_points
Includes Gopalganj as a pickup point for this trip.

🧩 drop_points
Includes Delhi as a drop point for this trip.*/



/*

This query to find the bus from Gopalgnaj to delhi but the bus start point is Siwan.

SELECT 
    bt.id AS trip_id,
    b.bus_name,
    bt.departure_time,
    pp.pickup_time,
    dp.drop_time
FROM 
    bus_trips bt
JOIN buses b ON b.id = bt.bus_id
JOIN pickup_points pp ON pp.trip_id = bt.id
JOIN drop_points dp ON dp.trip_id = bt.id
JOIN locations pl ON pl.id = pp.location_id
JOIN locations dl ON dl.id = dp.location_id
WHERE
    pl.city = 'Gopalganj'
    AND dl.city = 'Delhi'
    AND bt.travel_date = '2025-07-23'
    AND bt.is_active = TRUE
    AND pp.sort_order < dp.sort_order;  -- ensures correct travel direction



*/

