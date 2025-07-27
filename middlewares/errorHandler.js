function errorHandler(err, req, res, next) {
    console.error('🔥 Error caught:', err);

    // Default values
    const statusCode = err.statusCode || 500;
    const status = err.status || 'error';

    res.status(statusCode).json({
        status,
        message: err.message || 'Internal Server Error',
    });
}

module.exports = errorHandler;
