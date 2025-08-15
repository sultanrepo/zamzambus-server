const express = require('express');
const router = express.Router();
const authenticateToken = require('../middlewares/authMiddleware');
const {
    createLocation,
    getAllLocations,
    updateLocation,
    createCity,
    getCitiesByState,
    createState,
    getAllStates,
    createBusTrip,
    createRoute,
    getRoutesList,
    createPickupLocation,
    getPickupLocationsList,
    updatePickupLocation,
    createDropLocation,
    getDropLocationsList,
    updateDropLocation
} = require('../controllers/busRoutes');

router.post('/locations', createLocation);
router.get('/locationsList', getAllLocations);
router.post('/updateLocation', updateLocation);
router.post('/cities', createCity);
router.get('/cities/:stateId', getCitiesByState);
router.post('/states', createState);
router.get('/statesList', getAllStates);
router.post('/busTrips', createBusTrip);
router.post('/route', createRoute);
router.get('/routesList', getRoutesList);
router.post('/pickupLocation', createPickupLocation);
router.get('/getPickupLocationsList', getPickupLocationsList);
router.put('/updatePickupLocation', updatePickupLocation);
router.post('/dropLocation', createDropLocation);
router.get('/getDropLocationsList', getDropLocationsList);
router.put('/updateDropLocation', updateDropLocation);


module.exports = router;
