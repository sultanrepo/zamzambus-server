CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- hashed
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (
        role IN ('customer', 'admin', 'superadmin', 'employee', 'driver', 'manager', 'bus_owners')
    ),
    status VARCHAR(10) DEFAULT 'active' CHECK (
        status IN ('active', 'suspended')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    address TEXT,
    date_of_birth DATE
);


CREATE TABLE superadmins (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    privileges TEXT -- JSON or text log of permissions
);


CREATE TABLE admins (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    department VARCHAR(50),
    permissions TEXT
);


CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    position VARCHAR(50),
    shift_time VARCHAR(50),
    branch VARCHAR(100)
);


CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) NOT NULL,
    assigned_bus_id INT, -- can reference buses table later
    years_of_experience INT,
    shift_time VARCHAR(50)
);


CREATE TABLE managers (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    managed_region VARCHAR(100),
    team_size INT,
    report_to INT REFERENCES users(id) -- could point to a superadmin or senior manager
);


CREATE TABLE buses (
    id SERIAL PRIMARY KEY,
    bus_name VARCHAR(100) NOT NULL,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    bus_type VARCHAR(50) NOT NULL, -- e.g., 'AC Sleeper', 'Non-AC Seater'
    total_seats INT NOT NULL,
    seat_layout VARCHAR(20), -- e.g., '2x2', '1x3 Sleeper'
    amenities JSONB, -- e.g., ['WiFi', 'Water Bottle', 'Charging Point']
    images TEXT[], -- store multiple image URLs (hosted on CDN or S3)
    make VARCHAR(50), -- Manufacturer, e.g., Volvo
    model VARCHAR(50),
    manufacture_year INT,
    last_service_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    owner_id INT REFERENCES bus_owners(id) ON DELETE SET NULL,
    layout_id INT REFERENCES seat_layouts(id),
    average_rating FLOAT DEFAULT 0,
    total_reviews INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- New version of buses data table:-

CREATE TABLE buses (
    id SERIAL PRIMARY KEY,
    bus_name VARCHAR(100) NOT NULL,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    bus_type VARCHAR(50) NOT NULL, -- e.g., 'AC Sleeper', 'Non-AC Seater'
    total_seats INT NOT NULL,
    seat_layout VARCHAR(20), -- e.g., '2x2', '1x3 Sleeper'
    amenities JSONB, -- ['WiFi', 'Charging Point', ...]
    images TEXT[],
    make VARCHAR(50),
    model VARCHAR(50),
    manufacture_year INT,
    last_service_date DATE,
    next_service_due DATE,
    odo_meter INT,
    is_active BOOLEAN DEFAULT TRUE,
    is_operational BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    maintenance_note TEXT,
    
    insurance_number VARCHAR(100),
    insurance_expiry DATE,
    permit_number VARCHAR(100),
    permit_expiry DATE,
    
    cancellation_policy TEXT,
    max_luggage_kg INT DEFAULT 20,
    
    gps_enabled BOOLEAN DEFAULT FALSE,
    gps_device_id VARCHAR(100),
    
    has_upper_deck BOOLEAN DEFAULT FALSE,
    sleeper_rows INT DEFAULT 0,
    seater_rows INT DEFAULT 0,

    description TEXT,
    owner_id INT REFERENCES bus_owners(id) ON DELETE SET NULL,
    layout_id INT REFERENCES seat_layouts(id),
    
    average_rating FLOAT DEFAULT 0,
    total_reviews INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- images = ARRAY[
--  'https://cdn.zamzambus.com/bus1/front.jpg',
--  'https://cdn.zamzambus.com/bus1/interior.jpg'
-- ]

-- Sample Insert into buses

INSERT INTO buses (
    bus_name, registration_number, bus_type, total_seats, seat_layout,
    amenities, images, make, model, manufacture_year, description, owner_id
) VALUES (
    'GreenLine AC Sleeper', 'WB12G4567', 'AC Sleeper', 40, '2x1',
    '["WiFi", "Charging Port", "Water Bottle"]',
    ARRAY[
      'https://cdn.zamzambus.com/buses/bus123_front.jpg',
      'https://cdn.zamzambus.com/buses/bus123_seats.jpg'
    ],
    'Volvo', '9400XL', 2022, 'Premium sleeper coach with semi-recline beds.', 2
);


-- Seat layouts    ------------Not Used---------------
-- CREATE TABLE seat_layouts (
--   id SERIAL PRIMARY KEY,
--   name VARCHAR(50) NOT NULL UNIQUE,
--   rows INT NOT NULL,
--   columns INT NOT NULL,
--   description TEXT
-- );

CREATE TABLE layout_seats (
  id SERIAL PRIMARY KEY,
  layout_id INT NOT NULL REFERENCES seat_layouts(id) ON DELETE CASCADE,
  seat_label VARCHAR(10) NOT NULL,
  row_no INT NOT NULL,
  col_no INT NOT NULL,
  is_aisle BOOLEAN DEFAULT FALSE,
  is_sleeper BOOLEAN DEFAULT FALSE,
  CONSTRAINT uniq_layout_seat UNIQUE(layout_id, seat_label),
  CONSTRAINT uniq_layout_position UNIQUE(layout_id, row_no, col_no)
);

-- Link buses to layouts
ALTER TABLE buses
  ADD COLUMN layout_id INT REFERENCES seat_layouts(id);

-- Seats per trip instance
CREATE TABLE seats (
  id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  layout_seat_id INT NOT NULL REFERENCES layout_seats(id),
  seat_status VARCHAR(20) NOT NULL DEFAULT 'available',
  booking_id INT REFERENCES bookings(id),
  CONSTRAINT uniq_trip_layoutseat UNIQUE(trip_id, layout_seat_id)
);

CREATE TABLE bus_reviews (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    trip_id INT REFERENCES trips(id) ON DELETE SET NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, bus_id, trip_id) -- One review per trip/bus by user
);

ALTER TABLE buses
  ADD COLUMN layout_id INT REFERENCES seat_layouts(id) ;

CREATE TABLE bus_reviews (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bus_id INT NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    trip_id INT REFERENCES trips(id) ON DELETE SET NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, bus_id, trip_id) -- One review per trip/bus by user
);


-- Example Query: Get All Reviews for a Bus

SELECT r.rating, r.review, u.full_name, r.created_at
FROM bus_reviews r
JOIN users u ON r.user_id = u.id
WHERE r.bus_id = 12
ORDER BY r.created_at DESC;


/******************************************************************
 *  Table: bus_owners
 *  Purpose: Stores organisation‑level information for each bus
 *           owner / operator on ZamZamBus.
 *  Relationship: One‑to‑one with `users` (via user_id).
 ******************************************************************/
CREATE TABLE bus_owners (
    id                SERIAL PRIMARY KEY,

    /* ←── Link back to the owner’s login account in `users`  */
    user_id           INT UNIQUE
                           REFERENCES users(id)
                           ON DELETE CASCADE,

    /* ──  Legal / registration details  ───────────────────── */
    company_name      VARCHAR(150)  NOT NULL,
    legal_entity_type VARCHAR(50)   DEFAULT 'Proprietorship', -- LLP, Pvt Ltd, etc.
    gst_number        VARCHAR(25)   UNIQUE,                  -- or VAT / Tax ID
    pan_number        VARCHAR(15)   UNIQUE,                  -- India‑specific; use TIN/SSN elsewhere
    registration_doc  TEXT,          -- URL or path to certificate PDF

    /* ──  Contact & address  ──────────────────────────────── */
    contact_person    VARCHAR(100)  NOT NULL,
    email             VARCHAR(150),      -- optional separate ops email
    phone             VARCHAR(20),
    address_line1     VARCHAR(150),
    address_line2     VARCHAR(150),
    city              VARCHAR(100),
    state             VARCHAR(100),
    postcode          VARCHAR(20),
    country           VARCHAR(80),

    /* ──  Banking / payout  ───────────────────────────────── */
    bank_account_name VARCHAR(100),
    bank_account_no   VARCHAR(30),
    bank_ifsc_code    VARCHAR(15),    -- or SWIFT/BIC
    payout_method     VARCHAR(30) DEFAULT 'bank_transfer', -- bank_transfer | upi | cheque

    /* ──  Platform‑specific status  ───────────────────────── */
    is_verified       BOOLEAN DEFAULT FALSE,  -- KYC completed?
    onboarding_stage  VARCHAR(20) DEFAULT 'pending_docs', -- pending_docs | review | active
    rating            FLOAT   DEFAULT 0,      -- aggregate rating of owner’s fleet
    total_reviews     INT     DEFAULT 0,

    /* ──  Audit & housekeeping  ───────────────────────────── */
    notes             TEXT,                  -- internal admin notes
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Automatically keep updated_at in sync
CREATE OR REPLACE FUNCTION update_bus_owners_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bus_owners_updated
BEFORE UPDATE ON bus_owners
FOR EACH ROW EXECUTE PROCEDURE update_bus_owners_updated_at();
