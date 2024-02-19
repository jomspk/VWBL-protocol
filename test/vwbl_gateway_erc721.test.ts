import { Contract, utils } from "ethers"
import { ethers } from "hardhat"
import { assert, expect } from "chai"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

describe("VWBLGateway", async () => {
    let accounts: SignerWithAddress[]
    let owner: SignerWithAddress
    let minter1: SignerWithAddress
    let vwblGateway: Contract
    let gatewayProxy: Contract
    let accessControlCheckerByNFT: Contract
    let accessCondition: Contract
    let vwblERC721: Contract
    let vwblMetadata: Contract
    let transferVWBLNFTContract: Contract

    const TEST_DOCUMENT_ID1 = "0x7c00000000000000000000000000000000000000000000000000000000000000"
    const TEST_DOCUMENT_ID2 = "0x3c00000000000000000000000000000000000000000000000000000000000000"
    const TEST_DOCUMENT_ID3 = "0x6c00000000000000000000000000000000000000000000000000000000000000"
    const TEST_DOCUMENT_ID4 = "0x1c00000000000000000000000000000000000000000000000000000000000000"
    const TEST_DOCUMENT_ID5 = "0x8c00000000000000000000000000000000000000000000000000000000000000"
    const fee = utils.parseEther("1.0")
    const inputJson = '{"name": "hogehoge", "description": "hogehoge", "image": "hogehoge"}'

    before(async () => {
        accounts = await ethers.getSigners()
        owner = accounts[0]
        minter1 = accounts[1]
    })

    it("should deploy", async () => {
        const VWBLGateway = await ethers.getContractFactory("VWBLGateway")
        vwblGateway = await VWBLGateway.deploy(fee)

        const GatewayProxy = await ethers.getContractFactory("GatewayProxy")
        gatewayProxy = await GatewayProxy.deploy(vwblGateway.address)

        const AccessControlCheckerByNFT = await ethers.getContractFactory("AccessControlCheckerByNFT")
        accessControlCheckerByNFT = await AccessControlCheckerByNFT.deploy(gatewayProxy.address)

        const AccessCondition = await ethers.getContractFactory("AccessCondition")
        accessCondition = await AccessCondition.deploy()

        const VWBLERC721 = await ethers.getContractFactory("VWBLERC721")
        vwblERC721 = await VWBLERC721.deploy(gatewayProxy.address, accessControlCheckerByNFT.address, "Hello, VWBL")
    })

    it("should return false from hasAccessControl", async () => {
        const isPermitted = await vwblGateway.hasAccessControl(owner.address, TEST_DOCUMENT_ID1)
        assert.equal(isPermitted, false)
    })

    it("should successfully grant AccessControl under VWBL.mint()", async () => {
        const beforeBalance = await vwblGateway.provider.getBalance(vwblGateway.address)
        await vwblERC721.connect(owner).makeNFT("http://xxx.yyy.com", inputJson, TEST_DOCUMENT_ID1, {
            value: utils.parseEther("1"),
        })

        const afterBalance = await vwblGateway.provider.getBalance(vwblGateway.address)
        assert.deepEqual(afterBalance.sub(beforeBalance).eq(utils.parseEther("1.0")), true)

        const createdToken = await accessControlCheckerByNFT.documentIdToToken(TEST_DOCUMENT_ID1)
        assert.equal(createdToken.contractAddress, vwblERC721.address)

        const isPermitted = await vwblGateway.hasAccessControl(owner.address, TEST_DOCUMENT_ID1)
        assert.equal(isPermitted, true)
    })

    it("should successfully transfer nft and minter has access control", async () => {
        await vwblERC721.connect(owner).transferFrom(owner.address, minter1.address, 1)
        const isPermittedOfMinter = await vwblGateway.hasAccessControl(owner.address, TEST_DOCUMENT_ID1)
        assert.equal(isPermittedOfMinter, true)
        const isPermittedOfOwner = await vwblGateway.hasAccessControl(minter1.address, TEST_DOCUMENT_ID1)
        assert.equal(isPermittedOfOwner, true)
    })

    it("should fail to grant AccessControl to condition contract when fee amount is invalid", async () => {
        await expect(
            vwblGateway.connect(owner).grantAccessControl(TEST_DOCUMENT_ID4, accessCondition.address, minter1.address, {
                value: utils.parseEther("0.9"),
            })
        ).to.be.revertedWith("Fee is insufficient")

        await expect(
            vwblGateway.connect(owner).grantAccessControl(TEST_DOCUMENT_ID4, accessCondition.address, minter1.address, {
                value: utils.parseEther("1.1"),
            })
        ).to.be.revertedWith("Fee is too high")
    })

    it("should fail to grant AccessControl to condition contract when documentId is already used", async () => {
        await expect(
            vwblGateway.connect(owner).grantAccessControl(TEST_DOCUMENT_ID1, accessCondition.address, owner.address, {
                value: utils.parseEther("1"),
            })
        ).to.be.revertedWith("documentId is already used")
    })

    it("should successfully grant AccessControl to condition contract", async () => {
        const beforeBalance = await vwblGateway.provider.getBalance(vwblGateway.address)
        await vwblGateway
            .connect(owner)
            .grantAccessControl(TEST_DOCUMENT_ID4, accessCondition.address, minter1.address, {
                value: utils.parseEther("1"),
            })

        const afterBalance = await vwblGateway.provider.getBalance(vwblGateway.address)
        assert.deepEqual(afterBalance.sub(beforeBalance).eq(utils.parseEther("1")), true)

        const contractAddress = await vwblGateway.documentIdToConditionContract(TEST_DOCUMENT_ID4)
        assert.equal(contractAddress, accessCondition.address)
        await vwblGateway.payFee(TEST_DOCUMENT_ID4, owner.address, { value: fee })

        const isPermitted = await vwblGateway.hasAccessControl(owner.address, TEST_DOCUMENT_ID4)
        assert.equal(isPermitted, true)
    })

    // it("should fail to grant AccessControl to condition contract when documentId is already used", async () => {
    //     await expect(
    //         vwblGateway
    //             .connect(accounts[2])
    //             .grantAccessControl(TEST_DOCUMENT_ID4, accessCondition.address, accounts[0].address, {
    //                 value: utils.parseEther("1"),
    //             })
    //     ).to.be.revertedWith("documentId is already used")
    // })

    // TODO: 意味がわからん
    it("should hasAccessControl return false when condition contract return false", async () => {
        await accessCondition.setCondition(false)
        const isPermitted = await vwblGateway.hasAccessControl(owner.address, TEST_DOCUMENT_ID4)
        assert.equal(isPermitted, false)
    })

    it("should not set Access check contract from not contract owner", async () => {
        await expect(vwblERC721.connect(minter1).setAccessCheckerContract(minter1.address)).to.be.revertedWith(
            "Ownable: caller is not the owner"
        )
    })

    it("should set Access check contract from contract owner", async () => {
        await vwblERC721.connect(owner).setAccessCheckerContract(minter1.address)
        const newContract = await vwblERC721.accessCheckerContract()
        assert.equal(newContract, minter1.address)
    })
})
