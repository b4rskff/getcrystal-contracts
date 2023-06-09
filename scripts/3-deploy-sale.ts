import { Address, getRandomNonce, WalletTypes } from "locklift";

async function main() {
  const signer = (await locklift.keystore.getSigner("0"))!;
  // creating new account for Collection calling (or you can get already deployed by locklift.factory.accounts.addExistingAccount)
  const someAccount = await locklift.factory.accounts.addExistingAccount({
    type: WalletTypes.WalletV3,
    publicKey: signer.publicKey,
  });
  const { contract: sample, tx } = await locklift.factory.deployContract({
    contract: "Sale",
    publicKey: signer.publicKey,
    initParams: {
      _owner: someAccount.address,
      _nonce: getRandomNonce(),
    },
    constructorParams: {
      // startTime: Math.floor(Date.now() / 1000) + 3600, // just for example. Of course you should put timestamp you want (in seconds)
      // endTime: Math.floor(Date.now() / 1000) + 14400,
      // tokenRoot: TOKEN_ROOT_ADDRESS,
      creator: "0:2f859981030c9e25b1dca0d2862307eb1e30abfab9ec9ca1c4c98288f8752aff",
      sendRemainingGasTo: someAccount.address,
    },
    value: locklift.utils.toNano(1),
  });

  console.log(`Sale deployed at: ${sample.address.toString()}`);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.log(e);
    process.exit(1);
  });
