const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Crowdfunding contract", function () {
    let crowdfunding;
    let owner;
    let contributor;

    // Before each test, deploy a new instance of the Crowdfunding contract
    beforeEach(async function() {
        [owner, contributor] = await ethers.getSigners();
        const Crowdfunding = await ethers.getContractFactory("CrowdFund");
        crowdfunding = await Crowdfunding.deploy();
        await crowdfunding.deployed();
    });

    // test case: deploying a crowd funding contract
    it("Should create a campaign", async function() {
        await crowdfunding.connect(owner).createCampaign(
            "Test campaign",
            "Description of the test campaign",
            "https://res.cloudinary.com/dncsihhxg/image/upload/v1718485786/thrivefund/file_qqo7pe.jpg",
            1000,
            Math.floor(Date.now() / 1000) + 3600
        );
        const campaigns = await crowdfunding.getAllCampaigns();
        
        // check if there is exactly one campaigna dn its title matches the one we created
        expect(campaigns.length).to.equal(1);
        expect(campaigns[0].title).to.equal("Test campaign");
    });

    // test case: contributing to a campaign
    it("Should contribute to a campaign", async function() {
        await crowdfunding.connect(owner).createCampaign(
            "Test campaign",
            "Description of the test campaign",
            "https://res.cloudinary.com/dncsihhxg/image/upload/v1718485786/thrivefund/file_qqo7pe.jpg",
            1000,
            Math.floor(Date.now() / 1000) + 3600
        );
        await crowdfunding.connect(contributor).contribute(0, { value: 500 });
        const totalContributions = await crowdfunding.getTotalcontributions(0);

        expect(totalContributions).to.equal(500);
    })
})