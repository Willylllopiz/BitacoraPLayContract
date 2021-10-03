var fs = require('fs')
var path = require('path')
var MoneyBoxSettings = require('../build/contracts/MoneyBoxSettings')
var MoneyBox = require('../build/contracts/MoneyBox')
var BitacoraBasic = require('../build/contracts/test/BitacoraBasic')

console.log('The app has been configured.')
// console.log('Run "npm run dev" to start it.')

const tronboxJs = require('../tronbox').networks.shasta

const deployedInfo = {
  contractAddress: address,
  constractAddress: {
    BitacoraBasic: BitacoraBasic.networks[tronboxJs.network_id].address,
    MoneyBoxSettings: MoneyBoxSettings.networks[tronboxJs.network_id].address,
    MoneyBox: MoneyBox.networks[tronboxJs.network_id].address,
  },
  privateKey: tronboxJs.privateKey,
  fullHost: tronboxJs.fullHost
}

fs.writeFileSync(path.resolve(__dirname, '../build/deployed-info.js'),`var deployedInfo = ${JSON.stringify(deployedInfo, null, 2)}`)
