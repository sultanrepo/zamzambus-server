const express = require('express');
const router = express.Router();
const {
    createBus,
    getBusById,
    updateBus,
    getBusList
} = require('../controllers/bus');
const authenticateToken = require('../middlewares/authMiddleware');

router.post('/create-bus', createBus);
router.get('/getBusDetails/:id', getBusById);
router.put('/updateBusDetails', updateBus);
router.get('/getBusList', getBusList);


module.exports = router;
