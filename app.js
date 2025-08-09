require("dotenv").config();
const express = require('express');
const db = require('./config/db');
const app = express();
const cors = require('cors');
const PORT = process.env.PORT;

const authRoute = require('./routers/auth');
const users = require('./routers/users');
const bus = require('./routers/bus');
const busRoutes = require('./routers/busRoutes');
const errorHandler = require('./middlewares/errorHandler');

//Cors
app.use(cors({
    origin: 'http://localhost:3000',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true
}));

//Middleware
app.use(express.json());

//Auth
app.use('/api/auth', authRoute);

//Users
app.use('/api/users', users);

//Bus
app.use('/api/bus', bus);

//Bus Routes
app.use('/api/busRoutes', busRoutes);

//DB Connect Test
app.get('/test-db', async (req, res) => {
    try {
        const result = await db.raw("SELECT NOW()");
        const currentTime = result.rows[0].now;

        res.json({
            message: 'Connected Successfully with Knex!',
            time: currentTime
        });
    } catch (error) {
        console.error('Knex DB query error:', error);
        res.status(500).json({ error: 'Database Error' });
    }
});


app.get('/', (req, res) => {
    res.send("Bismillah Hir Rahmani Rahim");
});

const start = () => {
    app.listen(PORT, () => {
        console.log(`Running on PORT: ${PORT} Allahu Wakbar`);
    });
}

//Catch All route
app.use((req, res, next) => {
    const AppError = require('./utils/appErrors');
    next(new AppError(`Cannot find ${req.originalUrl} on this server`, 404));
});

//Centralize Error handler
app.use(errorHandler);

//Jest Testing
if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
        console.log("Testttttttttttttttttttttttttttttttt");
        console.log(`Sultan, Running on PORT: ${PORT} Allahu Wakbar`);
    });
}

module.exports = app; // <-- this line is required for tests

start();