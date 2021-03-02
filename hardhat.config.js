require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("./hardhat.helpers");
const { getConfig } = require("./lib/config");

/**
 * @name deploy-mainnet
 * @description Local Development Environment
 */
task("deploy-mainnet", "Local Development Environment").setAction(
  async function () {
    const config = getConfig("mainnet");

    // Deploy DAI
    await run("deploy-poolpower", {
      contractFactory: "PoolPowerDAI",
      name: "PoolPowerDAI",
      symbol: "ppDAI",
      token: config.poolpowerDAI.token,
      ticket: config.poolpowerDAI.ticket,
      pool: config.poolpowerDAI.pool,
      poolToken: config.poolpowerDAI.poolToken,
      feePerDeposit: config.poolpowerDAI.feePerDeposit,
      depositProcessMinimum: config.poolpowerDAI.depositMinium,
      minimumLiquidationAmount: config.poolpowerDAI.minimumLiquidationAmount,
      liquidationFee: config.poolpowerDAI.liquidationFee,
    });

    // Deploy USDC
    await run("deploy-poolpower", {
      contractFactory: "PoolPowerUSDC",
      name: "PoolPowerUSDC",
      symbol: "ppUSDC",
      token: config.poolpowerUSDC.token,
      ticket: config.poolpowerUSDC.ticket,
      pool: config.poolpowerUSDC.pool,
      poolToken: config.poolpowerUSDC.poolToken,
      feePerDeposit: config.poolpowerUSDC.feePerDeposit,
      depositProcessMinimum: config.poolpowerUSDC.depositMinium,
      minimumLiquidationAmount: config.poolpowerUSDC.minimumLiquidationAmount,
      liquidationFee: config.poolpowerUSDC.liquidationFee,
    });

    // Deploy UNI
    await run("deploy-poolpower", {
      contractFactory: "PoolPowerUNI",
      name: "PoolPowerUNI",
      symbol: "ppUNI",
      token: config.poolpowerUNI.token,
      ticket: config.poolpowerUNI.ticket,
      pool: config.poolpowerUNI.pool,
      poolToken: config.poolpowerUNI.poolToken,
      feePerDeposit: config.poolpowerUNI.feePerDeposit,
      depositProcessMinimum: config.poolpowerUNI.depositMinium,
      minimumLiquidationAmount: config.poolpowerUNI.minimumLiquidationAmount,
      liquidationFee: config.poolpowerUNI.liquidationFee,
    });

    // Deploy UNI
    await run("deploy-poolpower", {
      contractFactory: "PoolPowerCOMP",
      name: "PoolPowerCOMP",
      symbol: "ppUNI",
      token: config.poolpowerCOMP.token,
      ticket: config.poolpowerCOMP.ticket,
      pool: config.poolpowerCOMP.pool,
      poolToken: config.poolpowerCOMP.poolToken,
      feePerDeposit: config.poolpowerCOMP.feePerDeposit,
      depositProcessMinimum: config.poolpowerCOMP.depositMinium,
      minimumLiquidationAmount: config.poolpowerCOMP.minimumLiquidationAmount,
      liquidationFee: config.poolpowerCOMP.liquidationFee,
    });
  }
);

/**
 * @name deploy-rinkeby
 * @description Local Development Environment
 */
task("deploy-rinkeby", "Local Development Environment").setAction(
  async function () {
    const config = getConfig("rinkeby");

    // Deploy DAI
    await run("deploy-poolpower", {
      name: "PoolPowerDAI",
      symbol: "ppDAI",
      token: config.poolpowerDAI.token,
      ticket: config.poolpowerDAI.ticket,
      pool: config.poolpowerDAI.pool,
      poolToken: config.poolpowerDAI.poolToken,
      feePerDeposit: config.poolpowerDAI.feePerDeposit,
      depositProcessMinimum: config.poolpowerDAI.depositProcessMinimum,
    });

    // Deploy USDC
    await run("deploy-poolpower", {
      name: "USDC",
      token: config.poolpowerUSDC.token,
      ticket: config.poolpowerUSDC.ticket,
      pool: config.poolpowerUSDC.pool,
      poolToken: config.poolpowerUSDC.poolToken,
      feePerDeposit: config.poolpowerUSDC.feePerDeposit,
      depositMinium: config.poolpowerUSDC.depositMinium,
      chainId: config.poolpowerUSDC.chainId,
    });

    // Deploy BAT
    await run("deploy-poolpower", {
      name: "BAT",
      token: config.poolpowerBAT.token,
      ticket: config.poolpowerBAT.ticket,
      pool: config.poolpowerBAT.pool,
      poolToken: config.poolpowerBAT.poolToken,
      feePerDeposit: config.poolpowerBAT.feePerDeposit,
      depositMinium: config.poolpowerBAT.depositMinium,
      chainId: config.poolpowerBAT.chainId,
    });
  }
);

/**
 * @name deploy-poolpower
 * @description Deploy PoolPower Contract
 */
task("deploy-poolpower", "Deploy PoolPower")
  .addPositionalParam("contractFactory")
  .addPositionalParam("name")
  .addPositionalParam("token")
  .addPositionalParam("ticket")
  .addPositionalParam("pool")
  .addPositionalParam("poolToken")
  .addPositionalParam("feePerDeposit")
  .addPositionalParam("depositProcessMinimum")
  .addPositionalParam("minimumLiquidationAmount")
  .addPositionalParam("liquidationFee")
  .setAction(
    async ({
      contractFactory,
      name,
      symbol,
      token,
      ticket,
      pool,
      poolToken,
      feePerDeposit,
      depositProcessMinimum,
      minimumLiquidationAmount,
      liquidationFee,
    }) => {
      const Contract = await ethers.getContractFactory(contractFactory);
      const contract = await Contract.deploy(
        name,
        symbol,
        token,
        ticket,
        pool,
        poolToken,
        feePerDeposit,
        depositProcessMinimum,
        minimumLiquidationAmount,
        liquidationFee
      );
      await contract.deployed();
      console.log(
        `PoolPower${name}:`,
        ethers.utils.getAddress(contract.address)
      );

      return contract.address;
    }
  );

// Hardhat Configuration
module.exports = {
  defaultNetwork: "development",
  networks: {
    // HARDHAT CONFIGURATION
    hardhat: {
      gasPrice: 150000000000,
      gasLimit: 10000000,
      allowUnlimitedContractSize: true,
      chainId: 1,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
        // blockNumber: 11830000,
      },
      contracts: {},
    },
    // HARDHAT CONFIGURATION - Workaroundfor MetaMask port number
    development: {
      url: `http://localhost:8544`,
      gasPrice: 150000000000,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      contracts: {},
    },

    // MAINNET CONFIGURATION
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      gasPrice: 1000000000,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },

      deployed: {},
      owner: "0xC14438f1E3afF20a8e9b41a60F29a3ADFEf16B10",
      poolpowerDAI: {
        pool: "0xEBfb47A7ad0FD6e57323C8A42B2E5A6a4F68fc1a",
        token: "0x6b175474e89094c44da98b954eedeac495271d0f",
        ticket: "0x334cbb5858417aee161b53ee0d5349ccf54514cf",
        poolToken: "0x0cec1a9154ff802e7934fc916ed7ca50bde6844e",
        feePerDeposit: "30",
        depositMinium: "500",
        minimumLiquidationAmount: "2000",
        liquidationFee: "100",
        chainId: "1",
      },
      poolpowerUSDC: {
        pool: "0xde9ec95d7708b8319ccca4b8bc92c0a3b70bf416",
        token: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        ticket: "0xd81b1a8b1ad00baa2d6609e0bae28a38713872f7",
        poolToken: "0x0cec1a9154ff802e7934fc916ed7ca50bde6844e",
        feePerDeposit: "30",
        depositMinium: "500",
        minimumLiquidationAmount: "2000",
        liquidationFee: "100",
        chainId: "1",
      },
      poolpowerUNI: {
        pool: "0x0650d780292142835F6ac58dd8E2a336e87b4393",
        token: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
        ticket: "0xA92a861FC11b99b24296aF880011B47F9cAFb5ab",
        poolToken: "0x0cec1a9154ff802e7934fc916ed7ca50bde6844e",
        feePerDeposit: "30",
        depositMinium: "500",
        minimumLiquidationAmount: "2000",
        liquidationFee: "100",
        chainId: "1",
      },
      poolpowerCOMP: {
        pool: "0xBC82221e131c082336cf698F0cA3EBd18aFd4ce7",
        token: "0xc00e94cb662c3520282e6f5717214004a7f26888",
        ticket: "0x27b85f596feb14e4b5faa9671720a556a7608c69",
        poolToken: "0x0cec1a9154ff802e7934fc916ed7ca50bde6844e",
        feePerDeposit: "30",
        depositMinium: "500",
        minimumLiquidationAmount: "2000",
        liquidationFee: "100",
        chainId: "1",
      },
      contracts: {
        UniswapRouter: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
        UniswapFactory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
        DaiPrizePool: "0xEBfb47A7ad0FD6e57323C8A42B2E5A6a4F68fc1a",
        UsdcPrizePool: "0xde9ec95d7708b8319ccca4b8bc92c0a3b70bf416",
        CompPrizePool: "0xBC82221e131c082336cf698F0cA3EBd18aFd4ce7",
        UniPrizePool: "0x0650d780292142835F6ac58dd8E2a336e87b4393",
      },
      tokens: {
        DAI: "0x6b175474e89094c44da98b954eedeac495271d0f",
        UNI: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
        USDC: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        COMP: "0xc00e94cb662c3520282e6f5717214004a7f26888",
        WETH: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
      },
    },

    // RINKEBY CONFIGURATION
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: {
        mnemonic: process.env.MNEMONIC_RINKEBY,
      },
      poolpowerDAI: {
        pool: "0x4706856FA8Bb747D50b4EF8547FE51Ab5Edc4Ac2",
        ticket: "0x4FB19557Fbd8D73Ac884eFBe291626fD5641C778",
        token: "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa",
        poolToken: "0x0000000000000000000000000000000000000000",
        feePerDeposit: "10",
        depositMinium: "1000",
        chainId: "4",
        strategy: "0x5E0A6d336667EACE5D1b33279B50055604c3E329",
      },
      poolpowerUSDC: {
        pool: "0xde5275536231eCa2Dd506B9ccD73C028e16a9a32",
        strategy: "0x1b92BC2F339ef25161711e4EafC31999C005aF21",
        ticket: "0x334cbb5858417aee161b53ee0d5349ccf54514cf",
        token: "0x6b175474e89094c44da98b954eedeac495271d0f",
        poolToken: "0x0000000000000000000000000000000000000000",
        feePerDeposit: "30",
        depositMinium: "500",
        chainId: "4",
      },
      poolpowerBAT: {
        pool: "0xab068F220E10eEd899b54F1113dE7E354c9A8eB7",
        strategy: "0x41CF0758b7Cc2394b1C2dfF6133FEbb0Ef317C3b",
        ticket: "0xd5eE7cD7A97ccBbf2B1Fb2c92C19515a41720eA5",
        token: "0xbf7a7169562078c96f0ec1a8afd6ae50f12e5a99",
        poolToken: "0x0000000000000000000000000000000000000000",
        feePerDeposit: "30",
        depositMinium: "500",
        chainId: "4",
      },
    },
  },

  solidity: {
    compilers: [
      {
        version: "0.6.10",
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
