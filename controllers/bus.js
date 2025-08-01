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

const getBusById = async (req, res, next) => {
    const { id } = req.params;

    try {
        const bus = await knex('buses')
            .where({ id })
            .first();

        if (!bus) {
            return next(new AppError(`Bus with ID ${id} not found.`, 404));
        }

        return res.status(200).json({
            success: true,
            bus
        });
    } catch (err) {
        console.error('Error fetching bus:', err);
        return next(new AppError('Internal server error', 500));
    }
};

const updateBus = async (req, res, next) => {
    const {
        bus_id,
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
        amenities,
        images,
        gps_enabled,
        gps_device_id,
        is_active,
        is_operational,
        is_verified,
        owner_id,
        description
    } = req.body;

    try {
        const existingBus = await knex('buses').where({ id: bus_id }).first();
        if (!existingBus) {
            return next(new AppError(`Bus with ID ${bus_id} not found.`, 404));
        }

        if (
            registration_number &&
            registration_number !== existingBus.registration_number
        ) {
            const duplicateBus = await knex('buses')
                .where({ registration_number })
                .andWhereNot({ id: bus_id })
                .first();

            if (duplicateBus) {
                return next(
                    new AppError(
                        `Bus with registration number '${registration_number}' already exists.`,
                        409
                    )
                );
            }
        }

        const updatePayload = {
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
            amenities: JSON.stringify(amenities), // must be stringified for jsonb
            images: knex.raw('ARRAY[?]::text[]', [images]), // cast array to text[]
            gps_enabled,
            gps_device_id,
            is_active,
            is_operational,
            is_verified,
            owner_id,
            description
        };

        const [updatedBus] = await knex('buses')
            .where({ id: bus_id })
            .update(updatePayload)
            .returning('*');

        return res.status(200).json({
            success: true,
            message: 'Bus updated successfully.',
            bus: updatedBus
        });
    } catch (err) {
        console.error('Bus update error:', err);
        return next(new AppError('Internal server error', 500));
    }
};

const getBusList = async (req, res, next) => {
    try {
        const buses = await knex('buses')
            .select(
                'id',
                'bus_name',
                'registration_number',
                'bus_type',
                'make',
                'model',
                'manufacture_year',
                'odo_meter',
                'last_service_date',
                'next_service_due',
                'insurance_number',
                'insurance_expiry',
                'permit_number',
                'permit_expiry',
                'gps_enabled',
                'gps_device_id',
                'is_active',
                'is_operational',
                'is_verified',
                'owner_id',
                'max_luggage_kg',
                'amenities',
                'images',
                'description',
                'created_at',
                'updated_at'
            )
            .orderBy('created_at', 'desc');

        return res.status(200).json({
            success: true,
            message: 'Bus list fetched successfully.',
            count: buses.length,
            buses
        });
    } catch (err) {
        console.error('Error fetching bus list:', err);
        return next(new AppError('Internal server error', 500));
    }
};


module.exports = {
    createBus,
    getBusById,
    updateBus,
    getBusList
};
