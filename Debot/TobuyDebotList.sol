pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "TobuyDebot.sol";

contract TobuyDebotList is TobuyDebot{

    string m_buyAdd;    // Buy id for add

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() virtual public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "TOBUY DeBot LIST";
        version = "0.2.0";
        publisher = "TON Labs";
        key = "TOBUY list manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a TOBUY DeBot. Shall we make a shopping list?";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function _menu() public override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{} (paid/unpaid) items, cost of paid items:{}.",
                    m_purchase.paidPurchase,
                    m_purchase.unpaidPurchase,
                    m_purchase.totalPaid
            ),
            sep,
            [
                MenuItem("Add new item","",tvm.functionId(addBuy)),
                MenuItem("Show TOBUY list","",tvm.functionId(showList)),
                MenuItem("Delete item","",tvm.functionId(deleteBuy))
            ]
        );
    }


    function addBuy(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(addBuy_), "Name of item:", false);
    }

    function addBuy_(string value) public {
        m_buyAdd = value;
        Terminal.input(tvm.functionId(addBuy__), "Amount of item:", false);
    }

    function addBuy__(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        ITobuy(m_address).addBuy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_buyAdd, uint32(num));
    }

    function showList(uint32 index) virtual public view {
        index = index;
        optional(uint256) none;
        ITobuy(m_address).getBuy{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showList_),
            onErrorId: 0
        }();
    }

    function showList_(Buy[] purchases ) public {
        uint32 i;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your TOBUY list:");
            for (i = 0; i < purchases.length; i++) {
                Buy buy = purchases[i];
                string completed;
                if (buy.isDone) {
                    completed = '✓';
                } else {
                    completed = ' ';
                }
                Terminal.print(0, format("{} {} {} \"{}\"  at {}", buy.id, completed, buy.item, buy.amount, buy.createdAt));
            }
        } else {
            Terminal.print(0, "Your TOBUY list is empty");
        }
        _menu();
    } 

    function deleteBuy(uint32 index) public {
        index = index;
        if (m_purchase.unpaidPurchase> 0) {
            Terminal.input(tvm.functionId(deleteBuy_), "Enter item number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no item to delete");
            _menu();
        }
    }

    function deleteBuy_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        ITobuy(m_address).deleteBuy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }


}