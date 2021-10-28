var MoneyBoxSettings = artifacts.require("MoneyBoxSettings");
var SafeMath = artifacts.require("SafeMath");
var SafeAddress = artifacts.require("SafeAddress");
var SafeTRC20 = artifacts.require("SafeTRC20");
var MoneyBox = artifacts.require("MoneyBox");
var BitacoraPlay = artifacts.require("BitacoraPlay");

var TronWeb = require('tronweb');
var tronBoxInfo = require('../tronbox');
var config = tronBoxInfo.networks.shasta;
var tronWeb = new TronWeb({
    fullHost: config.fullHost,
});

module.exports = async (deployer) => {
    console.log('Deploying MoneyBoxSettings');
    await deployer.deploy(MoneyBoxSettings);

    console.log('Getting Deployed MoneyBoxSettings')
    const MoneyBoxSettingsContract = await MoneyBoxSettings.deployed();

    const moneyBoxSettingsAddress = await tronWeb.address.fromHex(MoneyBoxSettings.address);
    console.debug('MoneyBoxSettings address ++++++++++++++++ ', moneyBoxSettingsAddress)

    console.log('Initializing MoneyBoxSettings')
    await MoneyBoxSettingsContract.call('initialize', [process.env.USDT_IMPL]);
    console.log('Initialized MoneyBoxSettings   !!!!!!!!')

    //endregion

    //region Money Box

    console.log('Deploying SafeMath');
    await deployer.deploy(SafeMath);
    console.log('Linking SafeMath to SafeTRC20');
    await deployer.link(SafeMath, SafeTRC20);
    console.log('Deploying SafeAddress');
    await deployer.deploy(SafeAddress);
    console.log('Linking SafeAddress to SafeTRC20');
    await deployer.link(SafeAddress, SafeTRC20);
    console.log('Deploying SafeTRC20');
    await deployer.deploy(SafeTRC20);
    console.log('Linking SafeTRC20 to MoneyBox');
    await deployer.link(SafeTRC20, MoneyBox);

    console.log('Deploying MoneyBox');
    await deployer.deploy(MoneyBox);

    console.log('Getting Deployed MoneyBox')
    const MoneyBoxContract = await MoneyBox.deployed();
    const moneyBoxAddress = await tronWeb.address.fromHex(MoneyBox.address);
    console.debug('MoneyBox address ++++++++++++++++ ', moneyBoxAddress)

    
    //endregion


    //region BitacoraPlayBasic

    console.log('Deploying BitacoraPlay');
    await deployer.deploy(BitacoraPlay, process.env.ROOT_ADMIN_ADDRESS);

    console.log('Getting Deployed BitacoraPlay')
    const BitacoraPlayContract = await BitacoraPlay.deployed();
    const bitacoraPlayAddress = await tronWeb.address.fromHex(BitacoraPlay.address);
    console.debug('BitacoraPlay address ++++++++++++++++ ', bitacoraPlayAddress)

    console.log('Initializing BitacoraPlay')
    await BitacoraPlayContract.call('initialize', [process.env.USDT_IMPL, moneyBoxAddress, moneyBoxSettingsAddress]);
    console.log('BitacoraPlay initialized   !!!!!!!!')
    //endregion

    console.log('Initializing MoneyBox')
    await MoneyBoxContract.call('initialize', [process.env.USDT_IMPL, moneyBoxSettingsAddress, bitacoraPlayAddress]);
    console.log('Initialized MoneyBox     !!!!!!')

    // console.debug('\n\n[SAVE CONTRACTS ADDRESS] starting .... \n');
    // saveContractsInfo(bitacoraPlayAddress, moneyBoxAddress, moneyBoxSettingsAddress);
    // console.debug('[SAVE CONTRACTS ADDRESS] finished .... \n');
};
