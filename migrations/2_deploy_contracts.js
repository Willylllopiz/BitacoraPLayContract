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

async function saveContractsInfo(bitacora, moneyBox, moneyBoxSettings) {
    var fs = require('fs');
    var path = require('path');

    const fileExists = (file) => {
        return new Promise((resolve) => {
            fs.access(file, fs.constants.F_OK, (err) => {
                err ? resolve(false) : resolve(true)
            });
        })
    }

    var deployedInfo = (await fileExists(path.resolve(__dirname, '../build/deployed-info.js')))
        ? require('../build/deployed-info')
        : {};

    deployedInfo[config.network_id] = {
        contractAddress: {
            BitacoraPlay: bitacora,
            MoneyBoxSettings: moneyBoxSettings,
            MoneyBox: moneyBox,
        },
        privateKey: config.privateKey,
        fullHost: config.fullHost
    }

    await fs.writeFileSync(
        path.resolve(__dirname, '../build/deployed-info.js'),
        `module.exports = ${JSON.stringify(deployedInfo, null, 2)}`
    );

}

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

    console.log('Initializing MoneyBox')
    // todo: enlazar bitacora con moneyBox
    await MoneyBoxContract.call('initialize', [process.env.USDT_IMPL, moneyBoxSettingsAddress, process.env.BITACORA_TEST_IMPL]);
    console.log('Initialized MoneyBox     !!!!!!')
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

    console.debug('\n\n[SAVE CONTRACTS ADDRESS] starting .... \n');
    saveContractsInfo(bitacoraPlayAddress, moneyBoxAddress, moneyBoxSettingsAddress);
    console.debug('[SAVE CONTRACTS ADDRESS] finished .... \n');
};
