require("dotenv").config();
const ethers = require("ethers");

// Set API Key by specifying as parameter
const url = `wss://api.flare.network/flare/bc/C/ws?x-apikey=${process.env.API_KEY}`;

// Instantiate provider using WebsocketProvider
const provider = new ethers.providers.WebSocketProvider(url);

// Use for any request type
(async () => {
  const blockNumber = await provider.getBlockNumber();
  console.log({ blockNumber });
})();

// Listen to network events
provider.on("pending", (tx) => {
  provider.getTransaction(tx).then(function (transaction) {
    console.log(transaction);
  });
});

// wss://api.flare.network/flare/bc/C/ws?Xーapikey=TiryHtYzkt3Y1Bs6WGFEGhQb0GZayBZXSZOFAYNbS935DziF
