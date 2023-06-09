pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "@itgold/everscale-tip/contracts/TIP4_1/interfaces/ITIP4_1NFT.sol";
import "@itgold/everscale-tip/contracts/TIP4_1/interfaces/INftTransfer.sol";
// import "tip3/contracts/interfaces/IAcceptTokensTransferCallback.sol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";

contract Sale is INftTransfer {

  /**
    * Errors
    **/
    uint8 constant sender_is_not_owner = 101;
    uint8 constant value_is_less_than_required = 102;
    uint8 constant you_not_allowed_to_buy_it = 103;

  uint256 static _nonce; // random nonce for affecting on address
  address public _creator;
  // address public _tokenWallet;

  struct Sale {
    address owner;
    uint128 price;
    bool nftReceived;
    bool closed;
  }

  mapping (address => Sale) private offers;

  constructor(
    address creator,
    address sendRemainingGasTo
  ) public {
    tvm.accept();
    tvm.rawReserve(0.2 ever, 0);

    _creator = creator;

    // _tokenRoot = tokenRoot;
    // ITokenRoot(_tokenRoot).deployWallet {
    //         value: 0.2 ever,
    //         flag: 1,
    //         callback: Sell.onTokenWallet
    //     } (
    //         address(this),
    //         0.1 ever
    //     );
    //     // memento gas management :)
    //     sendRemainingGasTo.transfer({ value: 0, flag: 128, bounce: false });
  }

  // function onTokenWallet(address value) external {
  //       require (
  //           msg.sender.value != 0 &&
  //           msg.sender == _tokenRoot,
  //           101
  //       );
  //       tvm.rawReserve(0.2 ever, 0);
  //       // just store our auction's wallet address for future interaction
  //       _tokenWallet = value;
  //       _owner.transfer({ value: 0, flag: 128, bounce: false });
  // }

   function onNftTransfer(
        uint256, // id,
        address oldOwner,
        address, // newOwner,
        address, // oldManager,
        address, // newManager,
        address, // collection,
        address gasReceiver,
        TvmCell // payload
    ) override external {
        tvm.rawReserve(0.2 ever, 0);
        offers[msg.sender] = Sale(oldOwner, 0, true, true);
    }

    function openSale(address nft, uint128 price) public {
      require (msg.sender == offers[nft].owner, 101);
      offers[nft].price = price;
      offers[nft].closed = false;
      msg.sender.transfer({value: 0, flag: 128, bounce: false});
    }

    function buy(address nft) public {
      require (offers[nft].closed == false, 103);
      require (msg.value >= offers[nft].price + 3000000, 102);
      mapping(address => ITIP4_1NFT.CallbackParams) noCallbacks;
      TvmCell empty;
      ITIP4_1NFT(nft).transfer{
          value: 0.1 ever,
          flag: 1,
          bounce: false
      }(
          msg.sender,
          address(this),
          noCallbacks
      );
      address seller = offers[nft].owner;
      seller.transfer({ value: offers[nft].price, flag: 1, bounce: false});
      msg.sender.transfer({value: 0, flag: 128, bounce: false});
      delete offers[nft];
    }

    function closeSale(address nft) public {
      require (msg.sender == offers[nft].owner, 101);
      mapping(address => ITIP4_1NFT.CallbackParams) noCallbacks;
      ITIP4_1NFT(nft).transfer{
          value: 0.1 ever,
          flag: 1,
          bounce: false
      }(
          offers[nft].owner,
          msg.sender,
          noCallbacks
      );
      delete offers[nft];
    }

    function withdrawal(uint128 amount) public {
      require (msg.sender == _creator, 101);
      msg.sender.transfer({ value: amount, flag: 1, bounce: false });
      msg.sender.transfer({value: 0, flag: 128, bounce: false});
    }

    // function withdrawalAll() public {
    //   require (msg.sender == _creator, 101);
    //   msg.sender.transfer({value: 0.1 ever});
    //   msg.sender.transfer({value: 0, flag: 128, bounce: false});
    // }
}