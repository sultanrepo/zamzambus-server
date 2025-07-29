const knex = require('knex');
const dotenv = require('dotenv');

if (process.env.NODE_ENV === 'test') {
  dotenv.config({ path: '.env.test' });
} else {
  dotenv.config();
}

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
  .then(() => console.log('✅ Connected to Test PostgreSQL via Knex'))
  .catch((err) => console.error('❌ Knex DB connection failed:', err));

module.exports = db;
