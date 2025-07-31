const express = require('express');
const router = express.Router();
const { changeUserStatus, createBusOwner } = require('../controllers/users');

//Status Change route
router.patch('/status-change', changeUserStatus);
// Create new bus owner
router.post('/create-bus_owners', createBusOwner);

module.exports = router;