var ITRC20 = artifacts.require("ITRC20");
var CommonBasic = artifacts.require("CommonBasic");
var SettingsBasic = artifacts.require("SettingsBasic");
var MoneyBoxSettings = artifacts.require("MoneyBoxSettings");
var SafeMath = artifacts.require("SafeMath");
var SafeAddress = artifacts.require("SafeAddress");
var SafeTRC20 = artifacts.require("SafeTRC20");
var ICommonBasic = artifacts.require("ICommonBasic");
var ISettingsBasic = artifacts.require("ISettingsBasic");
var IMoneyBoxSettings = artifacts.require("IMoneyBoxSettings");
var MoneyBox = artifacts.require("MoneyBox");
var TronWeb = require('tronweb');
var config = require('../tronbox');

var tronWeb = new TronWeb({
    fullHost: config.networks.shasta.fullHost,
});

module.exports = async (deployer) => {

    //region Money Box Settings
    console.log('Deploying ITRC20');
    await deployer.deploy(ITRC20);
    console.log('Linking ITRC20 to CommonBasic');
    await deployer.link(ITRC20, CommonBasic);
    console.log('Deploying CommonBasic');
    await deployer.deploy(CommonBasic);
    console.log('Linking CommonBasic to SettingsBasic');
    await deployer.link(CommonBasic, SettingsBasic);
    console.log('Deploying SettingsBasic');
    await deployer.deploy(SettingsBasic);
    console.log('Linking SettingsBasic to MoneyBoxSettings');
    await deployer.link(SettingsBasic, MoneyBoxSettings);
    console.log('Deploying MoneyBoxSettings');
    await deployer.deploy(MoneyBoxSettings);

    console.log('Getting Deployed MoneyBoxSettings')
    const MoneyBoxSettingsContract = await MoneyBoxSettings.deployed();

    const moneyBoxSettingsAddress = await tronWeb.address.fromHex(MoneyBoxSettings.address);
    console.debug('MoneyBoxSettings address ++++++++++++++++ ', moneyBoxSettingsAddress)

    console.log('Initializing MoneyBoxSettings')
    await MoneyBoxSettingsContract.call('initialize', [process.env.USDT_IMPL]);

    //endregion

    //region Money Box
    console.log('Linking CommonBasic to MoneyBox');
    await deployer.link(CommonBasic, MoneyBox);

    console.log('Deploying SafeMath');
    await deployer.deploy(SafeMath);
    console.log('Linking SafeMath to SafeTRC20');
    await deployer.link(SafeMath, SafeTRC20);
    console.log('Deploying SafeAddress');
    await deployer.deploy(SafeAddress);
    console.log('Linking SafeAddress to SafeTRC20');
    await deployer.link(SafeAddress, SafeTRC20);
    console.log('Linking ITRC20 to SafeTRC20');
    await deployer.link(ITRC20, SafeTRC20);
    console.log('Deploying SafeTRC20');
    await deployer.deploy(SafeTRC20);
    console.log('Linking SafeTRC20 to MoneyBox');
    await deployer.link(SafeTRC20, MoneyBox);

    console.log('Deploying ICommonBasic');
    await deployer.deploy(ICommonBasic);
    console.log('Linking ICommonBasic to ISettingsBasic');
    await deployer.link(ICommonBasic, ISettingsBasic);
    console.log('Deploying ISettingsBasic');
    await deployer.deploy(ISettingsBasic);
    console.log('Linking ISettingsBasic to IMoneyBoxSettings');
    await deployer.link(ISettingsBasic, IMoneyBoxSettings);
    console.log('Linking ITRC20 to IMoneyBoxSettings');
    await deployer.link(ITRC20, IMoneyBoxSettings);
    console.log('Deploying IMoneyBoxSettings');
    await deployer.deploy(IMoneyBoxSettings);
    console.log('Linking IMoneyBoxSettings to MoneyBox');
    await deployer.link(IMoneyBoxSettings, MoneyBox);

    console.log('Getting Deployed MoneyBox')
    const MoneyBoxContract = await MoneyBox.deployed();
    const moneyBoxAddress = await tronWeb.address.fromHex(MoneyBox.address);
    console.debug('MoneyBox address ++++++++++++++++ ', moneyBoxAddress)

    console.log('Initializing MoneyBox')
    await MoneyBoxContract.call('initialize', [process.env.USDT_IMPL, moneyBoxSettingsAddress, process.env.BITACORA_TEST_IMPL]);
    //endregion

    //
    // await deployer.deploy(SmartLotto, 'TTSqi5jVfh2N6x9Voi4PsQiYUjUgRvQkhs', CareerPlan.address, Lotto.address, 'TEtK2n8SP7it7J3KeU7dFHZcAjGrSz3o3c');
    // const CareerPlanContract = await CareerPlan.deployed();
    // const smartLottoAddress = await tronWeb.address.fromHex(SmartLotto.address);
    // console.log('address smart lotto{+++++}', smartLottoAddress)
    // await CareerPlanContract.call('setSmartLottoAddress', [smartLottoAddress]);
    // // await CareerPlanContract.setSmartLottoAddress(smartLottoAddress);
    // const LottoContract = await Lotto.deployed();
    // await LottoContract.call('setSmartLottoAddress', [smartLottoAddress]);
    // // await LottoContract.setSmartLottoAddress(smartLottoAddress);
};
