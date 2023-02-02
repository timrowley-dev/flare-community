require("dotenv").config();
const axios = require("axios");

// Set headers and provide API key
const config = {
  headers: {
    "Content-type": "application/json",
    "x-apikey": process.env.API_KEY,
  },
};

// Set API Endpoint URI
const url = "https://api.flare.network/flare/bc/C/rpc";

// Set request data (Ethereum JSON-RPC)
const requestData = {
  jsonrpc: "2.0",
  method: "eth_blockNumber",
  params: [],
  id: 1,
};

// Make request
(async () => {
  const { data } = await axios.post(url, requestData, config);
  console.log(data);
})();
