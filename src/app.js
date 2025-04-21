const express = require('express');
const app = express();
const PORT = 8080; 

app.get('/', (req, res) => {
  res.send('Hello ! This is finocplus CI-CD Pipeline');
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://65.2.177.67:${PORT}`);
});

module.exports = server;
