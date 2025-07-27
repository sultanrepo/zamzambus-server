// config/db.js
const knex = require('knex');
require('dotenv').config();

const db = knex({
    client: 'pg',
    connection: {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
    },
    pool: { min: 0, max: 10 },
});

db.raw('SELECT 1')
    .then(() => console.log('✅ Connected to PostgreSQL via Knex'))
    .catch((err) => console.error('❌ Knex DB connection failed:', err));

module.exports = db;
