var fs = require('fs')
var path = require('path')
var MoneyBoxSettings = require('../build/contracts/MoneyBoxSettings')
var MoneyBox = require('../build/contracts/MoneyBox')
var BitacoraBasic = require('../build/contracts/test/BitacoraBasic')

console.log('The app has been configured.')
// console.log('Run "npm run dev" to start it.')

const tronboxJs = require('../tronbox').networks.nile

const deployedInfo = {
  contractAddress: address,
  constractAddress: {
    BitacoraBasic: BitacoraBasic.networks['3'].address,
    MoneyBoxSettings: MoneyBoxSettings.networks['3'].address,
    MoneyBox: MoneyBox.networks['3'].address,
  },
  privateKey: tronboxJs.privateKey,
  fullHost: tronboxJs.fullHost
}

fs.writeFileSync(path.resolve(__dirname, '../build/deployed-info.js'),`var deployedInfo = ${JSON.stringify(deployedInfo, null, 2)}`)
