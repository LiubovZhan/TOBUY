pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

struct Buy {
    uint32 id;
    string item;
    uint32 amount;
    uint32 createdAt;
    bool isDone;
    uint32 price;
}

struct SummaryBuy {
    uint32 paidPurchase;
    uint32 unpaidPurchase;
    uint32 totalPaid;
}
    
interface Wallet {
    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload  ) external;
}
    
abstract contract ATobuy {
    constructor(uint256 pubkey) public {}
}

interface ITobuy {
    function addBuy(string item, uint32 amount) external;
    function markBuy(uint32 id, uint32 price) external;
    function deleteBuy(uint32 id) external;
    function getBuy() external returns (Buy[] buy);
    function getSummaryBuy() external returns (SummaryBuy);
}