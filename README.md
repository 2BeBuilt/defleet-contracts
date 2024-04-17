# DeFleet.io

## SEPOLIA

- Mock XNET deployed at `0x20dB0C103641658e77aA14a8723940Cf8a72Ab57`
- Router `0x467Ba24340E6D0708c55Be62BDF9d3585bA0a110`

## Polygon

- Payment Router deployed on Polygon mainnet at `0x52F6DCA38F7F32779c488B400bbbf55882ddC0DE`

- DeFleet owner and treasury `0xec847ea7a57c347B6131F8F17ffa53de0974475C` gnosis multisig

# Router Contract Function Descriptions

## Transaction Functions

### `sendToken(address _token, address[] calldata _recipients, uint256[] calldata _amounts)`

Allows the batch sending of ERC20 tokens from the caller's address to multiple recipients. Includes fee handling based on sender's discount rate.

- **Parameters:**
  - `_token`: Address of the ERC20 token to be sent.
  - `_recipients`: Array of recipient addresses.
  - `_amounts`: Array of token amounts corresponding to each recipient.

### `sendNative(address[] calldata _recipients, uint256[] calldata _amounts)`

Allows the batch sending of native Ether from the caller's address to multiple recipients. Includes fee handling based on sender's discount rate.

- **Parameters:**
  - `_recipients`: Array of recipient addresses.
  - `_amounts`: Array of Ether amounts corresponding to each recipient.

## Fee Management Functions

### `setArrayLimit(uint256 _arrayLimit)`

Sets the maximum number of recipients that can be handled in a single transaction batch.

- **Parameters:**
  - `_arrayLimit`: The maximum number of recipients.

### `setDiscountStep(uint256 _discountStep)`

Sets the discount step which affects the transaction fee discounts given to users based on their transaction count.

- **Parameters:**
  - `_discountStep`: The discount step value.

### `setFee(uint256 _fee)`

Sets the fee required for transactions.

- **Parameters:**
  - `_fee`: The fee amount.

### `setBaseFee(uint256 _baseFee)`

Sets the base fee amount which acts as the minimum fee.

- **Parameters:**
  - `_baseFee`: The base fee amount.

### `setFeeManager(address _feeManager)`

Sets the address that can manage fee settings.

- **Parameters:**
  - `_feeManager`: Address of the new fee manager.

### `setFeeReceiver(address _feeReciever)`

Sets the address to which fees are paid.

- **Parameters:**
  - `_feeReciever`: Address of the fee receiver.

### `excludeFromFee(address _address)`

Excludes or includes an address from having to pay fees on transactions.

- **Parameters:**
  - `_address`: The address to be excluded or included from fees.

## Token Recovery Functions

### `recoverTokens(address _token)`

Allows recovery of ERC20 tokens or native Ether sent to this contract by mistake.

- **Parameters:**
  - `_token`: Address of the ERC20 token. If this is the fee receiver address, Ether is recovered.

## View Functions

### `getDiscountRate(address _user)`

Returns the discount rate for a given user based on their transaction count.

- **Parameters:**
  - `_user`: The address of the user.

### `getCurrentFee(address _user)`

Calculates the current fee for a given user, taking into account their discount rate.

- **Parameters:**
  - `_user`: The address of the user.

### `getFee()`

Returns the current transaction fee.

### `getBaseFee()`

Returns the current base fee.

### `getDiscountStep()`

Returns the current discount step.

### `getArrayLimit()`

Returns the maximum number of recipients allowed in a single transaction batch.
