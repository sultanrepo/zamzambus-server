const express = require('express');
const router = express.Router();
const {
    changeUserStatus,
    createBusOwner,
    getBusOwnerList,
    getBusOwnerById
} = require('../controllers/users');
const authenticateToken = require('../middlewares/authMiddleware');


//Status Change route
router.patch('/status-change', changeUserStatus);

// Create new bus owner
router.post('/create-bus_owners', createBusOwner);

// Get list of all bus owners
router.get('/getBusOwnerList', getBusOwnerList);

// Get single bus owner by ID
router.get('/getBusOwnerList/:id', getBusOwnerById);

module.exports = router;