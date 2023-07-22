const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

let tx,
  workID,
  reviews = [];

let sowToken, sowLibrary;

let owner, reader1, reader2, author1, author2, reviewer1, reviewer2, admin1, admin2, participants;

describe("SOW", function () {
  describe("Basic flow", function () {
    before(async function () {
      [sowLibrary, sowToken] = await initSOW();
      await initParticipants();
    });

    it("SOW Airdrop", async function () {
      let amountToAirDrop = hre.ethers.utils.parseEther("100");

      let amounts = [];
      for (i = 0; i < participants.length; i++) {
        amounts.push(amountToAirDrop);
      }

      tx = await sowToken.connect(owner).airdrop(participants, amounts);
      await tx.wait();

      // let's verify balances
      for (const participant of participants) {
        assert.equal((await sowToken.balanceOf(participant)).toString(), amountToAirDrop);
      }
    });

    it("owner set admins", async function () {
      tx = await sowLibrary.connect(owner).makeAdmin(admin1.address);
      await tx.wait();

      tx = await sowLibrary.connect(owner).makeAdmin(admin2.address);
      await tx.wait();
    });

    it("check the role of the new admins", async function () {
      assert.equal((await sowLibrary.getRole(admin1.address)).toString(), "5");

      assert.equal((await sowLibrary.getRole(admin2.address)).toString(), "5");
    });

    it("guests become participants", async function () {
      // let's verify balances

      tx = await sowLibrary.connect(reader1).join();
      await tx.wait();

      tx = await sowLibrary.connect(reader2).join();
      await tx.wait();

      tx = await sowLibrary.connect(author1).join();
      await tx.wait();

      tx = await sowLibrary.connect(author2).join();
      await tx.wait();

      tx = await sowLibrary.connect(reviewer1).join();
      await tx.wait();

      tx = await sowLibrary.connect(reviewer2).join();
      await tx.wait();
    });

    it("verify the number of participants", async function () {
      assert.equal((await sowLibrary.getRole(reader1.address)).toString(), "1");
      assert.equal((await sowLibrary.getRole(reader1.address)).toString(), "1");

      assert.equal((await sowLibrary.getRole(author1.address)).toString(), "1");
      assert.equal((await sowLibrary.getRole(author2.address)).toString(), "1");

      assert.equal((await sowLibrary.getRole(reviewer1.address)).toString(), "1");
      assert.equal((await sowLibrary.getRole(reviewer2.address)).toString(), "1");
    });

    it("participants become author", async function () {
      await sowLibrary.connect(author1).becomeAuthor();

      await sowLibrary.connect(author2).becomeAuthor();
    });

    it("participants become reviewer", async function () {
      const reviewerDeposit = (await sowLibrary.reviewerDepositAmount()).toString();

      await sowToken.connect(reviewer1).approve(sowLibrary.address, reviewerDeposit);
      await sowLibrary.connect(reviewer1).becomeReviewer();

      await sowToken.connect(reviewer2).approve(sowLibrary.address, reviewerDeposit);
      await sowLibrary.connect(reviewer2).becomeReviewer();
    });

    it("owner publishes author1's paper", async function () {
      workID = 11111111;
      await sowLibrary.connect(owner).publishPaper([author1.address], "My first work", "URL_AUTHOR_1", workID, 1000);
    });

    it("owner tries to publish author1's paper again", async function () {
      await expect(
        sowLibrary.connect(owner).publishPaper([author1.address], "My first work", "URL_AUTHOR_1", workID, 1000)
      ).to.be.revertedWith("SowLibrary: paper already exists");
    });

    it("get SPT address by work id", async function () {
      console.log(`spt work address: ${(await sowLibrary.getPaperById(workID)).toString()}`);
    });

    it("set reviews", async function () {
      const paperAddres = (await sowLibrary.getPaperById(workID)).toString();
      const SPTTokenFactory = await hre.ethers.getContractFactory("SPT");
      const sptToken = await SPTTokenFactory.attach(paperAddres);

      await sptToken.setReview(reviewer1.address, true);

      await sptToken.setReview(reviewer2.address, false);

      console.log((await sptToken.getReviewerDecision(reviewer1.address)).toString());

      console.log((await sptToken.getReviewerDecision(reviewer2.address)).toString());
    });

    // it("get author1's works", async function () {
    //   const worksData = await sowLibrary.getWorksByAuthor(author1.address);
    //   console.log(worksData);
    // });

    // it("reader tries to purchase the paper", async function () {
    //   await sowToken.connect(reader1).approve(sowLibrary.address, hre.ethers.utils.parseEther("10"));

    //   console.log(`balance of author before: ${(await sowToken.balanceOf(author1.address)).toString()}`);

    //   await expect(sowLibrary.connect(reader1).purchasePaper(workID)).to.be.revertedWith("SowLibrary: paper is not readable");

    //   console.log(`balance of author after: ${(await sowToken.balanceOf(author1.address)).toString()}`);
    // });

    it("add reviews on paper", async function () {
      await sowLibrary.connect(owner).addReviewsForPaper(workID, [reviewer1.address, reviewer2.address], [2, 2]);
    });

    // it("get paper status", async function () {
    //   const paperData = await sowLibrary.getWorksByAuthor(author1.address);
    //   const paperAddress = paperData[0];

    //   const SPTFactory = await hre.ethers.getContractFactory("SPT");
    //   const paper = SPTFactory.attach(paperAddress);

    //   console.log(`paper status: ${await paper.status()}`);
    // });

    it("reader purchases the paper", async function () {
      await sowToken.connect(reader1).approve(sowLibrary.address, hre.ethers.utils.parseEther("100"));

      console.log(`balance of author before: ${(await sowToken.balanceOf(author1.address)).toString()}`);

      await sowLibrary.connect(reader1).purchasePaper(workID);

      console.log(`balance of author after: ${(await sowToken.balanceOf(author1.address)).toString()}`);
    });

    // it("reviewers verify their rewards", async function () {
    //   console.log(`pending reviewer1 rewards: ${(await sowLibrary.getReviewerRewardsForWork(workID, reviewer1.address)).toString()}`);

    //   console.log(`pending reviewer2 rewards: ${(await sowLibrary.getReviewerRewardsForWork(workID, reviewer2.address)).toString()}`);

    //   console.log(`is able to claim(reviewer1) rewards: ${(await sowLibrary.isAbleToClaimForWork(workID, reviewer1.address)).toString()}`);
    //   console.log(`is able to claim(reviewer2) rewards: ${(await sowLibrary.isAbleToClaimForWork(workID, reviewer2.address)).toString()}`);
    // });

    return;
    // it("admin pushes reviews on the work", async function () {
    //   const test = 0x512345673440;
    //   const testBytes = ethers.utils.arrayify(test);
    //   const messageHash = ethers.utils.hashMessage(testBytes);

    //   //Sign the messageHash
    //   const messageHashBytes = ethers.utils.arrayify(messageHash);
    //   const signature = await signer.signMessage(testBytes);
    //   //Recover the address from signature
    //   const recoveredAddress = ethers.utils.verifyMessage(testBytes, signature);
    //   console.log("singerAddress                   :", signer.address);
    //   console.log("recovered address from ethers   :", recoveredAddress);

    //   const reviewer1Review = await reviewer1.signMessage(ethers.utils.arrayify(data));
    //   console.log(`reviewer1: ${reviewer1.address}`);
    //   // const reviewer2Review = await sign(reviewer2.address, [workID, 1]);

    //   reviews.push(reviewer1Review);
    //   // reviews.push(reviewer2Review);

    //   await sowLibrary.publishReviewsBatch(workID, [ethers.utils.arrayify(data)], reviews);
    // });
  });
});

const initSOW = async () => {
  console.log(`... Initialization of SOW ...`);

  // 1. SOW token
  const SowTokenFactory = await hre.ethers.getContractFactory("SOW");
  const sowToken = await SowTokenFactory.deploy();
  await sowToken.initialize();

  // 2. SOW Library
  const SowLibraryFactory = await hre.ethers.getContractFactory("SowLibrary");
  const sowLibrary = await SowLibraryFactory.deploy();
  await sowLibrary.initialize();

  await sowLibrary.setSowToken(sowToken.address);
  await sowToken.changeMinter(sowLibrary.address);

  // 3. SOW Work Factory
  const PaperFactoryFactory = await hre.ethers.getContractFactory("TokenFactory");
  const factory = await PaperFactoryFactory.deploy();

  await sowLibrary.setFactory(factory.address);
  await factory.setMinter(sowLibrary.address);

  return [sowLibrary, sowToken];
};

const initParticipants = async () => {
  [owner, reader1, reader2, author1, author2, reviewer1, reviewer2, admin1, admin2] = await ethers.getSigners();
  participants = [
    reader1.address,
    reader2.address,
    author1.address,
    author2.address,
    reviewer1.address,
    reviewer2.address,
    admin1.address,
    admin2.address,
  ];
};

function sign(address, data) {
  return hre.network.provider.send("eth_sign", [address, ethers.utils.hexlify(ethers.utils.toUtf8Bytes(data))]);
}
