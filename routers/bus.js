const express = require('express');
const router = express.Router();
const { createBus } = require('../controllers/bus');

router.post('/create-bus', createBus);

module.exports = router;
