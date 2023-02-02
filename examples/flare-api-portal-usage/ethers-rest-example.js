require("dotenv").config();
const ethers = require("ethers");

const url = "https://api.flare.network/flare/bc/C/rpc";

// Provide ConnectionInfo https://docs.ethers.org/v5/single-page/#/v5/api/utils/web/-%23-ConnectionInfo
const provider = new ethers.providers.JsonRpcProvider({
  url,
  headers: {
    "x-apikey": process.env.API_KEY,
  },
});

// Make Request
(async () => {
  const blockNumber = await provider.getBlockNumber();
  console.log({ blockNumber });
})();
