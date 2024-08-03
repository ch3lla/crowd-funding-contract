// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {
    address private immutable owner;
    uint private nextId = 1;
    Campaign[] public campaigns;
    bool private locked; // to prevent reentrant calls

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    struct Campaign {
        uint id;
        address campaignCreator;
        string title;
        string description;
        string imageURI;
        uint goal;
        uint startsAt;
        uint endsAt;
        STATUS status;
        uint totalContributions;
        address[] contributors;
        uint[] contributionAmounts;
    }

    enum STATUS {
        ACTIVE,
        DELETED,
        SUCCESSFUL,
        UNSUCCEEDED
    }

    event CampaignCreated(uint indexed campaignId, address campaignCreator, string title, STATUS status);
    event CampaignDeleted(uint indexed campaignId, address campaignCreator, STATUS status);
    event ContributionMade(uint indexed campaignId, address contributor, uint amount);
    event RefundMade(uint indexed campaignId, address contributor, uint amount);

    constructor () {
        owner = msg.sender;
    }

    function createCampaign(string memory title, string memory description, string memory imageURI, uint goal, uint endsAt) public {
        // input validation checks
        require(bytes(title).length > 0, 'Title must not be empty');
        require(bytes(description).length > 0, 'Description must not be empty');
        require(bytes(imageURI).length > 0, 'Image URI must not be empty');
        require(goal > 0, 'Goal must be greater than 0');
        require(endsAt > block.timestamp, 'End time of campaign muts be greater than current time');

        campaigns.push(Campaign(
            nextId++,
            msg.sender,
            title,
            description,
            imageURI,
            goal,
            block.timestamp,
            endsAt,
            STATUS.ACTIVE,
            0,
            new address[](0),
            new uint[](0)
        ));

        emit CampaignCreated(nextId - 1, msg.sender, title, STATUS.ACTIVE);
    }

    function contribute(uint campaignId) public payable nonReentrant {
        Campaign storage campaign = campaigns[campaignId];

        require(msg.value > 0, 'Contribution must be greater than 0 eth');

        uint remainingFundsNeeded = campaign.goal - campaign.totalContributions;

        if (msg.value <= remainingFundsNeeded) {
            campaign.totalContributions += msg.value;
        } else {
            uint excessAmount = msg.value - remainingFundsNeeded;
            uint refundedAmount = msg.value - excessAmount;

            payable (msg.sender).transfer(excessAmount);
            campaign.totalContributions += refundedAmount;

            if (campaign.totalContributions >= campaign.goal) {
                campaign.status = STATUS.SUCCESSFUL;
            }
        }

        campaign.contributors.push(msg.sender);
        campaign.contributionAmounts.push(msg.value);

        emit ContributionMade(campaignId, msg.sender, msg.value);
    }

    function deleteCampaign (uint campaignId) public {
        Campaign storage campaign = campaigns[campaignId];

        // only campaign oner can perfom this action
        require(campaign.campaignCreator == msg.sender);

        refund(campaignId);
        campaign.status = STATUS.DELETED;
        emit CampaignDeleted(campaignId, msg.sender, STATUS.DELETED);
    }

    function refund (uint campaignId) internal {
        Campaign storage campaign = campaigns[campaignId];

        for (uint i = 0; i < campaign.contributors.length; i++) {
            address contributor = campaign.contributors[i];
            uint contributionAmount = campaign.contributionAmounts[i];

            payable (contributor).transfer(contributionAmount);

            campaign.totalContributions -= contributionAmount;
        }
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    function getCampaignDetails (uint campaignId) public view returns (
        uint id,
        address campaignCreator,
        string memory title,
        string memory description,
        string memory imageURI,
        uint goal,
        uint startsAt,
        uint endsAt,
        STATUS status,
        uint totalContributions,
        address[] memory contributors,
        uint[] memory contributionAmounts
    ) {
        Campaign memory campaign = campaigns[campaignId];
        return (
            campaign.id,
            campaign.campaignCreator,
            campaign.title,
            campaign.description,
            campaign.imageURI,
            campaign.goal,
            campaign.startsAt,
            campaign.endsAt,
            campaign.status,
            campaign.totalContributions,
            campaign.contributors,
            campaign.contributionAmounts
        );
    }

    function getTotalcontributions(uint campaignId) public view returns (uint totalContributions) {
        return campaigns[campaignId].totalContributions;
    }

    function getLatestCampaigns() public view returns(Campaign[] memory){
        require(campaigns.length > 0, "No campaigns found.");

        uint startIndex = campaigns.length > 4 ? campaigns.length - 4 : 0;
        uint latestCampaignsCount = campaigns.length - startIndex;

        Campaign[] memory latestCampaigns = new Campaign[](latestCampaignsCount);

        for (uint i = 0; i < latestCampaignsCount; i++) {
            latestCampaigns[i] = campaigns[campaigns.length - 1 - i];
        }

        return latestCampaigns;
    }
}