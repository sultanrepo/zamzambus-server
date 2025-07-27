const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const AppError = require('../utils/appErrors');

const allowedRoles = ['customer', 'admin', 'superadmin', 'employee', 'driver', 'manager', 'bus_owners'];
const allowedStatuses = ['active', 'suspended', 'pending'];

//User Signup
const userSignup = async (req, res, next) => {
    const { full_name, email, password, phone, role, status } = req.body;
    if (!full_name || !email || !password || !phone || !role || !status) {
        return next(new AppError('All fields are required', 400));
    }
    if (!allowedRoles.includes(role)) {
        return next(new AppError('Invalid role', 400));
    }
    if (!allowedStatuses.includes(status)) {
        return next(new AppError('Invalid status', 400));
    }
    try {
        const isUserExists = await db('users').where({ email }).first();
        if (isUserExists) {
            return next(new AppError('Email already exists', 409));
        }
        const hashedPassword = await bcrypt.hash(password, 10);
        const [newUser] = await db('users').insert({
            full_name,
            email,
            password: hashedPassword,
            phone,
            role,
            status
        }).returning(['id', 'full_name', 'email', 'phone', 'role', 'status']);
        res.status(201).json({ message: 'User created successfully', user: newUser });
    } catch (err) {
        console.log("Signup error:", err);
        next(err);
    }
}


//User Login
const userLogin = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return next(new AppError('Email and Password are required', 400))
        }
        const user = await db('users').where({ email }).first();
        if (!user) {
            return next(new AppError('Invalid credentials', 401));
        }
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return next(new AppError('Invalid credentials', 401));
        }

        const token = jwt.sign(
            { userId: user.id, email: user.email, fullName: user.full_name },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );
        res.json({ token: token });
    } catch (err) {
        console.error('Login error', err);
        next(err);
    }
}

module.exports = { userSignup, userLogin };