var fs = require('fs')
var path = require('path')
var MoneyBoxSettings = require('../build/contracts/MoneyBoxSettings')
var MoneyBox = require('../build/contracts/MoneyBox')
var BitacoraPlay = require('../build/contracts/BitacoraPlay')

console.log('The app has been configured.')
// console.log('Run "npm run dev" to start it.')

const TronWeb = require('tronweb');
const tronboxJs = require('../tronbox').networks.shasta
var tronWeb = new TronWeb({
  fullHost: tronboxJs.fullHost,
});

const getAddress = (adr) => {
  return !!adr ? tronWeb.address.fromHex(adr) : '';
}

const deployedInfo = {
  [tronboxJs.network_id]: {
    contractAddress: {
      BitacoraPlay: getAddress(BitacoraPlay.networks[tronboxJs.network_id] ? BitacoraPlay.networks[tronboxJs.network_id].address : ''),
      MoneyBoxSettings: getAddress(MoneyBoxSettings.networks[tronboxJs.network_id] ? MoneyBoxSettings.networks[tronboxJs.network_id].address : ''),
      MoneyBox: getAddress(MoneyBox.networks[tronboxJs.network_id] ? MoneyBox.networks[tronboxJs.network_id].address : ''),
    },
    privateKey: tronboxJs.privateKey,
    fullHost: tronboxJs.fullHost
  }
}

fs.writeFileSync(path.resolve(__dirname, '../build/deployed-info.js'),`module.exports = ${JSON.stringify(deployedInfo, null, 2)}`)
