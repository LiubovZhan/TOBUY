pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../base/Debot.sol";
import "../base/Terminal.sol";
import "../base/Menu.sol";
import "../base/AddressInput.sol";
import "../base/ConfirmInput.sol";
import "../base/Upgradable.sol";
import "../base/Sdk.sol";
import "TobuyBase.sol";

abstract contract TobuyDebot is Debot, Upgradable {
    
    bytes m_icon;
    TvmCell m_tobuyStateInit;
    address m_address;  // TOBUY contract address
    SummaryBuy m_purchase;  // Statistics of purchase
    uint256 m_userPubKey; // User pubkey
    address m_walletAddress;  // User wallet address
    uint32 INITIAL_BALANCE =  200000000;  // Initial TOBUY contract balance


    function setTobuyCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_tobuyStateInit = tvm.buildStateInit(code, data);
    }


    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_userPubKey = res;
            Terminal.print(0, "Checking if you already have a TOBUY list ...");
            TvmCell deployState = tvm.insertPubkey(m_tobuyStateInit, m_userPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your TOBUY contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatusContract), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatusContract(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            getSummaryBuy(tvm.functionId(setSummaryBuy));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a TOBUY list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your TOBUY contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function onSuccess() public virtual{
        getSummaryBuy(tvm.functionId(setSummaryBuy));
    }

    function setSummaryBuy(SummaryBuy purchase) public {
        m_purchase = purchase;
        _menu();
    }

    function getSummaryBuy(uint32 answerId) public view {
        optional(uint256) none;
        ITobuy(m_address).getSummaryBuy{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function _menu() virtual public;

    
    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    
    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function creditAccount(address value) public {
        m_walletAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        Wallet(m_walletAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        // TOBUY: check errors if needed.
        sdkError;
        exitCode;
        creditAccount(m_walletAddress);
    }


    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkDeployContract), m_address);
    }

    function checkDeployContract(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }


    function deploy() private view {
            TvmCell image = tvm.insertPubkey(m_tobuyStateInit, m_userPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess),
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
                time: 0,
                expire: 0,
                sign: true,
                pubkey: none,
                stateInit: image,
                call: {ATobuy, m_userPubKey}
            });
            tvm.sendrawmsg(deployMsg, 1);
    }


    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        // TOBUY: check errors if needed.
        sdkError;
        exitCode;
        deploy();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}