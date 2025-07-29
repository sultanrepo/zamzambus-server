const db = require('../config/db_test'); // Not db.js

beforeAll(() => {
    jest.spyOn(console, 'error').mockImplementation((msg, err) => {
        // Show unexpected errors only
        if (
            err instanceof Error &&
            !['All fields are required', 'Email already exists'].includes(err.message)
        ) {
            // Allow unexpected errors to show
            console.warn('Unexpected error:', err.message);
        }
    });
});

beforeEach(async () => {
    await db.raw('TRUNCATE TABLE users RESTART IDENTITY CASCADE');
});

afterAll(async () => {
    await db.destroy();
});
