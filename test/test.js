const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("PoolPower", function () {
  describe("PoolPowerDAI", function () {
    let poolPowerDai;

    beforeEach(async () => {
      // deploy poolPowerDai
      const PoolPower = await ethers.getContractFactory("PoolPowerDAI");
      poolPowerDai = await PoolPower.deploy([]);
    });

    it("should have correct params set", async function () {
      const name = await poolPowerDai.name();
      expect(name).equal("PoolPowerDAI");

      const symbol = await poolPowerDai.symbol();
      expect(symbol).equal("ppDAI");
    });
  });
});
