const knex = require('../config/db');
const AppError = require('../utils/appErrors');

const createLocation = async (req, res, next) => {
    try {
        const { name, city, state, latitude, longitude, is_active, parent_city_id } = req.body;

        if (!name || !city || !state) {
            return next(
                new AppError('Name, city and State are required.', 400)
            );
        }

        const [newLocation] = await knex('locations')
            .insert({
                name,
                city,
                state: state || null,
                latitude: latitude || null,
                longitude: longitude || null,
                is_active: is_active !== undefined ? is_active : true,
                parent_city_id: parent_city_id || null
            })
            .returning('*'); // PostgreSQL specific

        res.status(201).json({
            message: 'Location added successfully.',
            location: newLocation
        });

    } catch (error) {
        console.error('Error adding location:', error);
        next(new AppError('Internal server error', 500));
    }
};

const updateLocation = async (req, res, next) => {
    try {
        const { id, name, city, state, latitude, longitude, is_active, parent_city_id } = req.body;

        if (!id || !name || !city || !state) {
            return next(new AppError('All fields are required.', 400));
        }

        // Build update payload dynamically
        const updateData = {};
        if (name !== undefined) updateData.name = name;
        if (city !== undefined) updateData.city = city;
        if (state !== undefined) updateData.state = state;
        if (latitude !== undefined) updateData.latitude = latitude;
        if (longitude !== undefined) updateData.longitude = longitude;
        if (is_active !== undefined) updateData.is_active = is_active;
        if (parent_city_id !== undefined) updateData.parent_city_id = parent_city_id;

        if (Object.keys(updateData).length === 0) {
            return next(new AppError('No fields provided to update.', 400));
        }

        const updatedRows = await knex('locations')
            .where({ id })
            .update(updateData)
            .returning('*');

        if (updatedRows.length === 0) {
            return next(new AppError('Location not found.', 404));
        }

        res.status(200).json({
            message: 'Location updated successfully.',
            location: updatedRows[0]
        });

    } catch (error) {
        console.error('Error updating location:', error);
        return next(new AppError('Internal server error.', 500));
    }
};

const getAllLocations = async (req, res, next) => {
    try {
        const locations = await knex('locations')
            .select('id', 'name', 'city', 'state', 'latitude', 'longitude', 'is_active', 'parent_city_id')
            .orderBy('id', 'desc');
        res.status(200).json({
            total: locations.length,
            locations
        });
    } catch (error) {
        console.error('Error fetching locations:', error);
        next(new AppError('Internal server error', 500));
    }
};

const createCity = async (req, res, next) => {
    try {
        const { name, state_id } = req.body;

        if (!name || !state_id) {
            return next(new AppError('City name and state_id are required', 400));
        }

        // Optional: normalize city name
        const trimmedName = name.trim();

        // Insert city
        const [newCity] = await knex('cities')
            .insert({ name: trimmedName, state_id })
            .returning('*');

        res.status(201).json({
            message: 'City added successfully.',
            city: newCity
        });

    } catch (error) {
        if (error.code === '23505') {
            // Unique violation
            return next(new AppError('City already exists in this state.', 409));
        }
        console.error('Error adding city:', error);
        return next(new AppError('Internal server error.', 500));
    }
};

const getCitiesByState = async (req, res, next) => {
    try {
        const { stateId } = req.params;

        if (!stateId) {
            return next(new AppError('State ID is required.', 400));
        }

        const cities = await knex('cities')
            .select('id', 'name')
            .where({ state_id: stateId });

        res.status(200).json({
            state_id: stateId,
            cities
        });

    } catch (error) {
        console.error('Error fetching cities:', error);
        return next(new AppError('Internal server error', 500));
    }
};

const createState = async (req, res, next) => {
    try {
        const { name } = req.body;
        if (!name) {
            return next(new AppError('State name is required.', 400));
        }
        const trimmedName = name.trim();
        const [newState] = await knex('states')
            .insert({ name: trimmedName })
            .returning('*');
        res.status(201).json({
            message: 'State added successfully.',
            state: newState
        });
    } catch (error) {
        if (error.code === '23505') {
            // Unique violation (state already exists)
            return next(new AppError('State already exists.', 409));
        }
        console.error('Error inserting state:', error);
        next(new AppError('Internal server error', 500));
    }
};

const getAllStates = async (req, res, next) => {
    try {
        const states = await knex('states')
            .select('id', 'name')
            .orderBy('name', 'asc');

        res.status(200).json({
            total: states.length,
            states
        });

    } catch (error) {
        console.error('Error fetching states:', error);
        next(new AppError('Internal server error', 500));
    }
};

const createBusTrip = async (req, res, next) => {
    try {
        const {
            bus_id,
            source_location_id,
            destination_location_id,
            departure_time,
            arrival_time,
            travel_date,
            is_recurring,
            days_of_week,
            is_active
        } = req.body;

        const errors = [];

        // Basic validations
        if (!bus_id) errors.push('bus_id is required.');
        if (!source_location_id) errors.push('source_location_id is required.');
        if (!destination_location_id) errors.push('destination_location_id is required.');
        if (!departure_time) errors.push('departure_time is required.');
        if (!arrival_time) errors.push('arrival_time is required.');
        if (!travel_date) errors.push('travel_date is required.');

        // Logical check
        if (source_location_id === destination_location_id) {
            errors.push('Source and destination locations cannot be the same.');
        }

        // Validate recurring trip and days_of_week
        if (is_recurring === true) {
            if (!Array.isArray(days_of_week)) {
                errors.push('days_of_week must be an array when is_recurring is true.');
            } else {
                const allowedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                const invalidDays = days_of_week.filter(day => !allowedDays.includes(day));
                if (invalidDays.length > 0) {
                    errors.push(`Invalid days in days_of_week: ${invalidDays.join(', ')}`);
                }
            }
        }

        if (errors.length > 0) {
            return next(new AppError(`Validation failed: ${errors.join(' ')}`, 400));
        }

        // Insert into DB
        const [newTrip] = await knex('bus_trips')
            .insert({
                bus_id,
                source_location_id,
                destination_location_id,
                departure_time,
                arrival_time,
                travel_date,
                is_recurring: is_recurring || false,
                days_of_week: is_recurring ? days_of_week : null,
                is_active: is_active !== undefined ? is_active : true
            })
            .returning('*');

        res.status(201).json({
            message: 'Bus trip created successfully.',
            trip: newTrip
        });

    } catch (error) {
        console.error('Error creating bus trip:', error);
        next(new AppError('Internal server error', 500));
    }
};

const createRoute = async (req, res, next) => {
    try {
        const { route_name, source_location_id, destination_location_id, via, status } = req.body;

        // Validation
        if (!route_name || !source_location_id || !destination_location_id) {
            return next(new AppError("route_name, source_location_id and destination_location_id are required", 400));
        }

        // Insert into DB
        const [newRoute] = await knex("routes")
            .insert({
                route_name,
                source_location_id,
                destination_location_id,
                via: via && Array.isArray(via) ? via : null,
                status: status || "active"
            })
            .returning("*");

        res.status(201).json({
            message: "Route created successfully",
            data: newRoute
        });
    } catch (error) {
        console.error("Error creating route:", error);
        next(new AppError("Internal Server Error", 500));
    }
};

const getRoutesList = async (req, res, next) => {
    try {
        const routes = await knex('routes as r')
            .leftJoin('locations as sl', 'r.source_location_id', 'sl.id')
            .leftJoin('locations as dl', 'r.destination_location_id', 'dl.id')
            .select(
                'r.id',
                'r.route_name',
                'r.source_location_id',
                knex.raw('sl.name as source_location_name'),
                'r.destination_location_id',
                knex.raw('dl.name as destination_location_name'),
                'r.via',
                'r.status'
            )
            .orderBy('r.id', 'asc');

        res.status(200).json({
            success: true,
            count: routes.length,
            data: routes
        });
    } catch (error) {
        console.error('Error fetching routes list:', error);
        return next(new AppError('Server Error', 500));
    }
};

const createPickupLocation = async (req, res, next) => {
    try {
        const { name, city, state, latitude, longitude, sort_order, is_active } = req.body;

        let errors = {};

        if (!name) {
            errors.name = "Name is required.";
        }
        if (!city) {
            errors.city = "City is required.";
        }
        if (!state) {
            errors.state = "State is required."
        }
        if (Object.keys(errors).length > 0) {
            return next(new AppError(errors, 400));
        }

        const [newLocation] = await knex('pickup_locations')
            .insert({
                name,
                city,
                state,
                latitude,
                longitude,
                sort_order: sort_order || 0,
                is_active: is_active !== undefined ? is_active : true
            })
            .returning('*'); // Returns the inserted row

        res.status(201).json({
            success: true,
            message: "Pickup location created successfully",
            data: newLocation
        });
    } catch (error) {
        console.error('Error creating pickup location:', error);
        return next(new AppError('Server error', 500));
    }
};



module.exports = {
    createLocation,
    updateLocation,
    createCity,
    getCitiesByState,
    getAllLocations,
    createState,
    getAllStates,
    createBusTrip,
    createRoute,
    getRoutesList,
    createPickupLocation
};
