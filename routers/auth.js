const express = require('express');
const router = express.Router();
const { userSignup, userLogin } = require('../controllers/auth');

router.post('/login', userLogin);
router.post('/signup', userSignup);

module.exports = router
