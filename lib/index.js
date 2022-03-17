const ethers = require('ethers')

// These constants must match the ones used in the smart contract.
const SIGNING_DOMAIN_NAME = "LazyNFT-Voucher"
const SIGNING_DOMAIN_VERSION = "1"

/**
 * LazyMinter is a helper class that creates NFTVoucher objects and signs them, to be redeemed later by the LazyNFT contract.
 */
class LazyMinter {

  constructor({ contract, signer, chainId }) {
    this.contract = contract
    this.signer = signer
    this.chainId = chainId
  }

  async createVoucher(minter, randomString, uri, royaltiesPercentage, minPrice = 0) {
    const voucher = { minter, randomString, minPrice, uri, royaltiesPercentage};
    const domain = await this._signingDomain()
    const types = {
      NFTVoucher: [
        {name: "minter", type: "address"},
        {name: "randomString", type: "string"},
        {name: "minPrice", type: "uint256"},
        {name: "uri", type: "string"},
        {name: "royaltiesPercentage", type: "uint256"},   
      ]
    }
    const signature = await this.signer._signTypedData(domain, types, voucher)
    return {
      ...voucher,
      signature,
    }
  }

  /**
   * @private
   * @returns {object} the EIP-721 signing domain, tied to the chainId of the signer
   */
  async _signingDomain() {
    if (this._domain != null) {
      return this._domain
    }
    this._domain = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contract.address,
      chainId: this.chainId,
    }
    return this._domain
  }
}

module.exports = {
  LazyMinter
}