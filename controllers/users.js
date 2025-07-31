const knex = require('../config/db');
const AppError = require('../utils/appErrors');

//Change the Users Status
const changeUserStatus = async (req, res, next) => {
    const { id, status } = req.body;

    if (!id || !['active', 'suspended'].includes(status)) {
        return next(new AppError('Invalid input: id and valid status required.', 400));
    }

    try {
        const updatedRows = await knex('users')
            .where({ id })
            .update({ status })
            .returning(['id', 'full_name', 'email', 'status']);

        if (updatedRows.length === 0) {
            return next(new AppError('User not found.', 404));
        }

        return res.status(200).json({
            message: 'User status updated successfully.',
            user: updatedRows[0],
        });
    } catch (error) {
        console.error('Error updating user status:', error);
        return res.status(500).json({ message: 'Internal server error.' });
    }
};

//Create Bus Owners
const createBusOwner = async (req, res, next) => {
    const {
        user_id,
        company_name,
        legal_entity_type,
        gst_number,
        pan_number,
        registration_doc,
        contact_person,
        email,
        phone,
        address_line1,
        address_line2,
        city,
        state,
        postcode,
        country,
        bank_account_name,
        bank_account_no,
        bank_ifsc_code,
        payout_method,
        notes
    } = req.body;

    if (!user_id || !company_name || !contact_person) {
        return next(new AppError('Missing required fields: user_id, company_name, contact_person.', 400));
    }

    try {
        // Check each unique field separately
        const existingChecks = [
            { field: 'user_id', value: user_id },
            { field: 'gst_number', value: gst_number },
            { field: 'pan_number', value: pan_number },
            { field: 'email', value: email },
            { field: 'phone', value: phone }
        ];

        for (const check of existingChecks) {
            if (!check.value) continue;

            const exists = await knex('bus_owners')
                .where(check.field, check.value)
                .first();

            if (exists) {
                return next(
                    new AppError(`Conflict: bus owner with this '${check.field}' already exists.`, 409)
                );
            }
        }

        const [busOwner] = await knex('bus_owners')
            .insert({
                user_id,
                company_name,
                legal_entity_type,
                gst_number,
                pan_number,
                registration_doc,
                contact_person,
                email,
                phone,
                address_line1,
                address_line2,
                city,
                state,
                postcode,
                country,
                bank_account_name,
                bank_account_no,
                bank_ifsc_code,
                payout_method,
                notes
            })
            .returning('*');

        res.status(201).json({
            message: 'Bus owner created successfully.',
            busOwner
        });

    } catch (error) {
        console.error('Error creating bus owner:', error);
        return res.status(500).json({ message: 'Internal server error.' });
    }
};

module.exports = {
    changeUserStatus,
    createBusOwner
};
