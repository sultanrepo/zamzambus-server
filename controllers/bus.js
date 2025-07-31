const knex = require('../config/db');
const AppError = require('../utils/appErrors');

const createBus = async (req, res, next) => {
    const {
        bus_name,
        registration_number,
        bus_type,
        make,
        model,
        manufacture_year,
        odo_meter,
        last_service_date,
        next_service_due,
        maintenance_note,
        insurance_number,
        insurance_expiry,
        permit_number,
        permit_expiry,
        max_luggage_kg = 20,
        amenities,
        images,
        gps_enabled = false,
        gps_device_id,
        is_active = true,
        is_operational = true,
        is_verified = false,
        owner_id,
        description
    } = req.body;

    try {
        // ✅ Check if registration_number already exists
        const existingBus = await knex('buses')
            .where({ registration_number })
            .first();

        if (existingBus) {
            return next(
                new AppError(
                    `Bus with registration number '${registration_number}' already exists.`,
                    409
                )
            );
        }

        // ✅ Insert into the database
        const [newBus] = await knex('buses')
            .insert({
                bus_name,
                registration_number,
                bus_type,
                make,
                model,
                manufacture_year,
                odo_meter,
                last_service_date,
                next_service_due,
                maintenance_note,
                insurance_number,
                insurance_expiry,
                permit_number,
                permit_expiry,
                max_luggage_kg,
                amenities: JSON.stringify(amenities),  // ✅ stringify JSONB field
                images,
                gps_enabled,
                gps_device_id,
                is_active,
                is_operational,
                is_verified,
                owner_id,
                description
            })
            .returning('*');

        return res.status(201).json({
            success: true,
            message: 'Bus created successfully.',
            bus: newBus
        });
    } catch (err) {
        console.error('Bus creation error:', err);
        return next(new AppError('Internal server error', 500));
    }
};

module.exports = {
    createBus
};
