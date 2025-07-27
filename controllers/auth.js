const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { Router } = require('express');
const AppError = require('../utils/appErrors');

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

module.exports = { userLogin };