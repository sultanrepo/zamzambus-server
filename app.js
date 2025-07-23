require("dotenv").config();
const express = require('express');
const app = express();
const PORT = process.env.PORT;


app.get('/', (req, res) => {
    res.send("Bismillah Hir Rahmani Rahim");
});

const start = () => {
    app.listen(PORT, () => {
        console.log(`Running on PORT: ${PORT} Allahu Wakbar`);
    });
}

start();