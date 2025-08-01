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
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. bus_trips (Each scheduled run of a bus)
-- 🔁 This replaces complex route modeling with a simple trip from A → B.

CREATE TABLE bus_trips (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    source_location_id INT REFERENCES locations(id),
    destination_location_id INT REFERENCES locations(id),
    
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP,

    travel_date DATE NOT NULL, -- for one-off or recurring logic

    is_recurring BOOLEAN DEFAULT FALSE,
    days_of_week VARCHAR(20), -- if recurring: 'Mon,Tue,Wed'

    is_active BOOLEAN DEFAULT TRUE
);

-- 3. pickup_points (locations where boarding is allowed for this trip)

CREATE TABLE pickup_points (
    id SERIAL PRIMARY KEY,
    trip_id INT REFERENCES bus_trips(id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id),
    pickup_time TIME NOT NULL,
    sort_order INT NOT NULL -- for sequencing the pickups
);

-- 4. drop_points (locations where passengers can get off)

CREATE TABLE drop_points (
    id SERIAL PRIMARY KEY,
    trip_id INT REFERENCES bus_trips(id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id),
    drop_time TIME NOT NULL,
    sort_order INT NOT NULL -- for sequencing the drops
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

