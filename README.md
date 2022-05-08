
<h1 align="center"><b>JediMarketPlace NFT Smart Contract</b></h3>

<div align="left">


[![Language](https://img.shields.io/badge/language-solidity-orange.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

</div>

---

<p align="center"><h2 align="center"><b>Solidity Smart contract for NFT MarketPlace
    </h2></b><br> 
</p>

## 📝 Table of Contents

- [EtherScan Link](#etherscan)
- [Installing](#install)
- [Contract Functions](#functions)
- [Deploy & Test Scripts](#scripts)
- [HardHat Tasks](#tasks)

## 🚀 Link on EtherScan <a name = "etherscan"></a>
JediMarketPlace for ERC721 and ERC1155: <br>
https://rinkeby.etherscan.io/address/0x2Dd01B1Edfbc280302b1b74b0e7338a6e983b9aA#code<br>




## 🚀 Installing <a name = "install"></a>
- Set initial values on scripts/deploy.ts file
- Deploy four contracts running on console:
```shell
node scripts/deploy.ts
```
- Copy address of deployed contract and paste to .env file as CONTRACT_ADDRESS_MARKET
- Use mint721 and mint1155 functions




## ⛓️ Contract Functions <a name = "functions"></a>

- **createItem()**
>Mints new ERC721 token with URI<br>

- **createItem1155()**
>Mints new ERC1155 token with given amount<br>

- **listItem()**
>Lists ERC721 token with given price and id<br>

- **listItem1155()**
>Lists ERC1155 token with given price and id<br>

- **cancel()**
>Cancels listing of ERC721 token with given id<br>

- **cancel1155()**
>Cancels listing of ERC1155 token with given id<br>

- **buyItem()**
>Buys ERC721 token<br>

- **buyItem1155()**
>Buys ERC1155 token<br>

- **listItemOnAuction()**
>Lists ERC721 token with given minPrice and id on auction for 3 days<br>

- **listItemOnAuction1155()**
>Lists ERC1155 token with given minPrice and id on auction for 3 days<br>

- **cancelAuction()**
>Cancels auction of ERC721 token with given id after 3 days<br>

- **cancelAuction1155()**
>Cancels auction of ERC1155 token with given id after 3 days<br>

- **finishAuction()**
>Finishes auction of ERC721 token with given id after 3 days<br>

- **finishAuction1155()**
>Finishes auction of ERC1155 token with given id after 3 days<br>

- **makeBid()**
>Creates bid on ERC721 token with given price<br>

- **makeBid1155()**
>Creates bid on ERC1155 token with given price<br>






## 🎈 Deploy & Test Scripts <a name = "scripts"></a>

```shell
node scripts/deploy.js --network rinkeby
npx hardhat test
```


## 💡 HardHat Tasks <a name = "tasks"></a>


```shell
npx hardhat mint721
npx hardhat mint1155
```
```

