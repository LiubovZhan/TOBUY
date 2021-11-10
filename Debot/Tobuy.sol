pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "TobuyBase.sol";

contract Tobuy {
   
    uint256 m_ownerPubkey;
    uint32 m_id;

    mapping(uint32 => Buy) m_buy;

    constructor(uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

    function getBuy() public view returns (Buy[] purchases) {
        string item; 
        uint32 amount; 
        uint32 createdAt; 
        bool isDone; 
        uint32 price;

        for((uint32 id, Buy buy) : m_buy) {
            item = buy.item;
            amount = buy.amount;
            createdAt = buy.createdAt;
            isDone = buy.isDone;
            price = buy.price;
            purchases.push(Buy(id, item, amount, createdAt, isDone, price));
       }
    }

    function getSummaryBuy() public view returns (SummaryBuy summarybuy) {
        uint32 paidPurchase;
        uint32 unpaidPurchase;
        uint32 totalPaid;

        for((, Buy buy) : m_buy) {
            if  (buy.isDone) {
                paidPurchase ++;
                totalPaid += buy.price;
            } else {
                unpaidPurchase ++;
            }
        }
        summarybuy = SummaryBuy(paidPurchase, unpaidPurchase, totalPaid);
    }


    function addBuy(string item, uint32 amount) public onlyOwner {
        tvm.accept();
        m_id++;
        m_buy[m_id] = Buy(m_id, item, amount, now, false, 0);
    }

    function deleteBuy(uint32 id) public onlyOwner {
        tvm.accept();
        delete m_buy[id];
    }

    function markBuy(uint32 id, uint32 price) public onlyOwner {
        tvm.accept();
        m_buy[id].isDone = true;
        m_buy[id].price = price;
    }
    
}
