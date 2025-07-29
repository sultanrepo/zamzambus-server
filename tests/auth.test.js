const request = require('supertest');
const app = require('../app');


//Signup User Test
describe('User Signup API', () => {
    it('Should signup a new user successfully', async () => {
        const response = await request(app)
            .post('/api/auth/signup')
            .send({
                full_name: 'Test User',
                email: 'test@example.com',
                password: 'Test@1234',
                phone: '1234567890',
                role: 'customer',
                status: 'active'
            });

        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('message', 'User created successfully');
        expect(response.body.user).toMatchObject({
            full_name: 'Test User',
            email: 'test@example.com',
            phone: '1234567890',
            role: 'customer',
            status: 'active'
        });
    });

    it('should return error for missing fields', async () => {
        const response = await request(app)
            .post('/api/auth/signup')
            .send({
                email: 'incomplete@gmail.com'
            });

        expect(response.status).toBe(400);
        expect(response.body.message).toBe('All fields are required');
    });

    it('should reject duplicate emails', async () => {
        // First signup
        await request(app)
            .post('/api/auth/signup')
            .send({
                full_name: 'Dup User',
                email: 'dup@example.com',
                password: 'Test@1234',
                phone: '1112223333',
                role: 'customer',
                status: 'active'
            });

        // Second signup with same email
        const response = await request(app)
            .post('/api/auth/signup')
            .send({
                full_name: 'Dup User 2',
                email: 'dup@example.com',
                password: 'AnotherPass123',
                phone: '1112223333',
                role: 'customer',
                status: 'active'
            });

        expect(response.status).toBe(409);
        expect(response.body.message).toBe('Email already exists');
    })
});


// Login User Test
const jwt = require('jsonwebtoken');

describe('User Login API', () => {
    const testUser = {
        full_name: 'Login Test User',
        email: 'login@test.com',
        password: 'Login@1234',
        phone: '9998887777',
        role: 'customer',
        status: 'active'
    };

    beforeEach(async () => {
        // Signup the user for login
        await request(app).post('/api/auth/signup').send(testUser);
    });

    it('should login successfully and return a valid JWT token', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: testUser.email,
                password: testUser.password
            });

        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('token');

        const token = response.body.token;
        expect(typeof token).toBe('string');
        expect(token.split('.')).toHaveLength(3); // Basic JWT structure: header.payload.signature

        // Optionally decode and verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        expect(decoded).toHaveProperty('userId');
        expect(decoded).toHaveProperty('email', testUser.email);
        expect(decoded).toHaveProperty('fullName', testUser.full_name);
    });

    it('should return error for missing email or password', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({ email: testUser.email });

        expect(response.status).toBe(400);
        expect(response.body.message).toBe('Email and Password are required');
    });

    it('should return error for invalid email', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'wrong@email.com',
                password: testUser.password
            });

        expect(response.status).toBe(401);
        expect(response.body.message).toBe('Invalid credentials');
    });

    it('should return error for incorrect password', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                email: testUser.email,
                password: 'WrongPassword'
            });

        expect(response.status).toBe(401);
        expect(response.body.message).toBe('Invalid credentials');
    });
});

