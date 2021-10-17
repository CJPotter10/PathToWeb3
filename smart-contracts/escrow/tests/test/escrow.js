const Escrow = artifacts.require('Escrow');

const assertError = async (promise, error) => {
  try {
    await promise;
  } catch(e) {
    assert(e.message.includes(error))
    return;
  }
  assert(false);
}

contract('Escrow', accounts => {
  let escrow = null;
  const [lawyer, payer, recipient] = accounts;
  before(async () => {
    escrow = await Escrow.deployed();
  });

  it('should deposit', async () => {
    await escrow.deposit({from: payer, value: 900});
    const escrowBalance = parseInt(await web3.eth.getBalance(escrow.address));
    assert(escrowBalance === 900);
  });

  it('should NOT deposit if transfer exceed total escrow amount', async () => {
    assertError(
      escrow.deposit({from: payer, value: 1000}),
      'Cant send more than escrow amount'
    );
  });

  it('should NOT deposit if not sending from payer', async () => {
    assertError(
      escrow.deposit({from: accounts[5]}),
      'Sender must be the payer'
    );
  });

  it('should NOT release if full amount not received', async () => {
    assertError(
      escrow.release({from: lawyer}),
      'cannot release funds before full amount is sent'
    );
  });
  
});