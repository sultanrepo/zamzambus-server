const express = require('express');
const router = express.Router();
const {
    createBus,
    getBusById,
    updateBus,
    getBusList
} = require('../controllers/bus');
const authenticateToken = require('../middlewares/authMiddleware');

router.post('/create-bus', authenticateToken, createBus);
router.get('/getBusDetails/:id', authenticateToken, getBusById);
router.put('/updateBusDetails', authenticateToken, updateBus);
router.get('/getBusList', getBusList);


module.exports = router;
