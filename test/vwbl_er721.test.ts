import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs"
import { expect } from "chai"
import { ethers } from "hardhat"

const feeWei = ethers.parseEther("0.001")
const vwblNetworkUrl = "http://xxx.yyy.com"

const inputJson = '{"name": "hogehoge", "description": "hogehoge", "image": "hogehoge"}'
const encodeJson =
    "data:application/json;base64,eyJuYW1lIjogImhvZ2Vob2dlIiwgImRlc2NyaXB0aW9uIjogImhvZ2Vob2dlIiwgImltYWdlIjogImhvZ2Vob2dlIn0="

describe("Getter function", function () {
    async function deployTokenFixture() {
        // account
        const [owner, minter1, minter2, minter3] = await ethers.getSigners()
        // VWBL Gateway
        const VWBLGateway = await ethers.deployContract("VWBLGateway", [feeWei])
        const vwblGateway = await VWBLGateway.waitForDeployment()
        // Gateway Proxy
        const GatewayProxy = await ethers.deployContract("GatewayProxy", [vwblGateway.target])
        const gatewayProxy = await GatewayProxy.waitForDeployment()
        // VWBL NFT
        const AccessControlCheckerByNFT = await ethers.deployContract("AccessControlCheckerByNFT", [
            gatewayProxy.target,
        ])
        const nftChecker = await AccessControlCheckerByNFT.waitForDeployment()
        const VWBLNFT_1 = await ethers.deployContract("VWBLERC721", [
            gatewayProxy.target,
            nftChecker.target,
            "Hello, VWBL",
        ])
        const vwblNFT_1 = await VWBLNFT_1.waitForDeployment()
        const VWBLNFT_2 = await ethers.deployContract("VWBLERC721", [
            gatewayProxy.target,
            nftChecker.target,
            "Hello, VWBL {{nonce}}",
        ])
        const vwblNFT_2 = await VWBLNFT_2.waitForDeployment()
        return {
            vwblGateway,
            vwblNFT_1,
            vwblNFT_2,
            nftChecker,
            owner,
            minter1,
            minter2,
            minter3,
        }
    }

    // 説明：正しくmintして、transferできるかを調べるテスト
    describe("Mint", function () {
        it("Should Mint initial Diary successfully", async function () {
            const { vwblNFT_1, vwblNFT_2, nftChecker, owner, minter1, minter2, minter3 } =
                await loadFixture(deployTokenFixture)
            // Diaryのmint
            const documentIdArray_1 = ethers.randomBytes(32)
            const documentId_1 = ethers.hexlify(documentIdArray_1)
            await vwblNFT_1.connect(owner).mintInitialDiary(vwblNetworkUrl, inputJson, documentId_1, { value: feeWei })
            // Initial diaryをmintした人が保有している権限を持っているか確認
            expect((await nftChecker.getOwnerAddress(documentId_1)) === owner.address).to.equal(true)
            // mintしていないアドレスがnftの権限を保有していないことを確認
            expect((await nftChecker.getOwnerAddress(documentId_1)) === minter3.address).to.equal(false)

            // TokenURI
            const tokens_1 = await vwblNFT_1.getTokenByMinter(owner.address)
            expect(await vwblNFT_1.connect(owner).tokenURI(tokens_1[0])).to.equal(encodeJson)

            // TokenIdToMinterとminterToDocumentIdに正常に値が入っているか確認
            expect((await vwblNFT_1.getMinter(tokens_1[0])) === owner.address).to.equal(true)
            expect((await vwblNFT_1.getDocumentId(owner.address)) === documentId_1).to.equal(true)

            //NFTのtransfer
            await vwblNFT_1.connect(owner).transferFrom(owner.address, minter3.address, tokens_1[0])
            expect((await nftChecker.getOwnerAddress(documentId_1)) === owner.address).to.equal(false)
            expect((await nftChecker.getOwnerAddress(documentId_1)) === minter3.address).to.equal(true)

            // Another Contract
            // 他のdocumentIdとアドレスでmint
            const documentIdArray_2 = ethers.randomBytes(32)
            const documentId_2 = ethers.hexlify(documentIdArray_2)
            await vwblNFT_2.connect(owner).mintInitialDiary(vwblNetworkUrl, inputJson, documentId_2, { value: feeWei })
            expect((await nftChecker.getOwnerAddress(documentId_2)) === owner.address).to.equal(true)
            expect((await nftChecker.getOwnerAddress(documentId_2)) === minter3.address).to.equal(false)

            // transfer
            const tokens_2 = await vwblNFT_2.getTokenByMinter(owner.address)
            await vwblNFT_2.connect(owner).transferFrom(owner.address, minter3.address, tokens_2[0])
            expect((await nftChecker.getOwnerAddress(documentId_2)) === owner.address).to.equal(false)
            expect((await nftChecker.getOwnerAddress(documentId_2)) === minter3.address).to.equal(true)
        })

        it("should mint another diary successfully", async () => {
            const { vwblNFT_1, vwblNFT_2, nftChecker, owner, minter1, minter2, minter3 } =
                await loadFixture(deployTokenFixture)
            // Diaryのmint
            const documentIdArray_3 = ethers.randomBytes(32)
            const documentId_3 = ethers.hexlify(documentIdArray_3)
            await vwblNFT_1.connect(owner).mintAnotherDiary(vwblNetworkUrl, inputJson, documentId_3)
            const tokens_1 = await vwblNFT_1.getTokenByMinter(owner.address)
            const tokenListLength = tokens_1.length
            expect((await vwblNFT_1.getMinter(tokens_1[tokenListLength - 1])) === owner.address).to.equal(true)
            expect((await vwblNFT_1.getDocumentId(owner)) === documentId_3).to.equal(false)
        })
        // description: NFTをmintする人とtransferする人がownerでない場合、エラーが発生するかどうか確認
        it("should not mint and transfer except contract owner", async () => {
            const { vwblNFT_1, nftChecker, owner, minter1, minter3 } = await loadFixture(deployTokenFixture)
            const documentIdArray_4 = ethers.randomBytes(32)
            const documentId_4 = ethers.hexlify(documentIdArray_4)
            await expect(
                vwblNFT_1.connect(minter1).mintInitialDiary(vwblNetworkUrl, inputJson, documentId_4, { value: feeWei }),
            ).to.be.revertedWithCustomError(vwblNFT_1, "OwnableUnauthorizedAccount")
            await expect(
                vwblNFT_1.connect(minter1).mintAnotherDiary(vwblNetworkUrl, inputJson, documentId_4),
            ).to.be.revertedWithCustomError(vwblNFT_1, "OwnableUnauthorizedAccount")

            // NFTのmint
            await vwblNFT_1.connect(owner).mintInitialDiary(vwblNetworkUrl, inputJson, documentId_4, { value: feeWei })
            // transfer
            const tokens_3 = await vwblNFT_1.getTokenByMinter(owner.address)
            await expect(
                vwblNFT_1.connect(minter1).transferFrom(minter1.address, minter3.address, tokens_3[0]),
            ).to.be.revertedWithCustomError(vwblNFT_1, "ERC721InsufficientApproval")
        })
    })

    describe("Owner", function () {
        // description: ownerがちゃんとownerの権限をminter1に移すことができているか確認
        it("should change owner", async function () {
            const { vwblNFT_1, nftChecker, owner, minter1 } = await loadFixture(deployTokenFixture)
            await vwblNFT_1.connect(owner).transferOwnership(minter1.address)
            expect(await vwblNFT_1.connect(owner).owner()).to.equal(minter1.address)
        })
        it("should not change owner except owner", async function () {
            const { vwblNFT_1, nftChecker, minter1, minter2 } = await loadFixture(deployTokenFixture)
            await expect(vwblNFT_1.connect(minter1).transferOwnership(minter2.address)).to.be.revertedWithCustomError(
                vwblNFT_1,
                "OwnableUnauthorizedAccount",
            )
        })
    })

    //説明:NFTを6個作った時にdocumentIdがコントラクトに6つ保存されているのかの確認
    describe("Getter function", function () {
        it("should getNFTDatas() successfully work", async function () {
            const { vwblNFT_1, vwblNFT_2, nftChecker, owner } = await loadFixture(deployTokenFixture)

            // Mint
            await vwblNFT_1
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })
            await vwblNFT_1
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })
            await vwblNFT_1
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })

            await vwblNFT_2
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })
            await vwblNFT_2
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })
            await vwblNFT_2
                .connect(owner)
                .mintInitialDiary(vwblNetworkUrl, inputJson, ethers.randomBytes(32), { value: feeWei })
            // getNFTDatas
            // 別々のdocumentIdでNFTを6個作った時にちゃんとdocumentIdが6個登録されているかの確認
            const nftDatas = await nftChecker.getNFTDatas()
            const nftDocumentIds = nftDatas[0]
            expect(nftDocumentIds.length).to.equal(6)
        })

        // サインメッセージを獲得できるか
        describe("Sign Message", function () {
            it("Should message to be signed of contracts successfully get", async function () {
                const { vwblNFT_1, vwblNFT_2 } = await loadFixture(deployTokenFixture)
                expect(await vwblNFT_1.getSignMessage()).to.equal("Hello, VWBL")
                expect(await vwblNFT_2.getSignMessage()).to.equal("Hello, VWBL {{nonce}}")
            })

            // サインメッセージを変更できるか
            it("Should message to be signed of contracts successfully change", async function () {
                const { owner, vwblNFT_1 } = await loadFixture(deployTokenFixture)
                const sampleSignMessge1 = "vwblNFT_1 {{nonce}}"

                // change sign message
                await vwblNFT_1.connect(owner).setSignMessage(sampleSignMessge1)

                // check sign message
                expect(await vwblNFT_1.getSignMessage()).to.equal(sampleSignMessge1)
            })
        })

        //説明: allowOriginの設定と取得ができるか
        describe("Allow Origins", function () {
            it("Should allow origin successfully set and getted. Only owner is able to call set method", async function () {
                const { owner, minter1, vwblNFT_1 } = await loadFixture(deployTokenFixture)

                //Act
                await vwblNFT_1.connect(owner).setAllowOrigins("https://example1.com")
                //Assert
                expect(await vwblNFT_1.connect(minter1).getAllowOrigins()).to.equal("https://example1.com")
                //Act
                await vwblNFT_1.connect(owner).setAllowOrigins("https://example2.com, https://example3.com")
                //Assert
                expect(await vwblNFT_1.connect(minter1).getAllowOrigins()).to.equal(
                    "https://example2.com, https://example3.com",
                )
                expect(vwblNFT_1.connect(minter1).setAllowOrigins("https://example3.com")).to.be.revertedWith(
                    "Ownable: caller is not the owner",
                )
            })
        })
    })
})
