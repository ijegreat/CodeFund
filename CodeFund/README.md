# CodeFund Savings Pool

A decentralized savings pool smart contract built on Stacks blockchain that enables community-driven rotating savings and credit association (ROSCA). This contract allows participants to contribute funds regularly and take turns receiving the accumulated pool balance.

## Overview

CodeFund implements a transparent and trustless savings mechanism where members:
- Join a savings pool with a fixed number of participants
- Make regular contributions in STX tokens
- Receive distributions on a rotating basis
- Benefit from community-driven accountability

## Features

- Fixed participant limit (2-100 members)
- Automated contribution tracking
- Rotating distribution system
- Built-in safeguards against double contributions
- Full transparency of pool status and member activities

## Contract Functions

### Administrative Functions

#### `initialize-pool`
- Parameters:
  - `participant-limit`: Maximum number of participants (2-100)
  - `required-amount`: Required contribution amount per round
- Initializes the savings pool with basic parameters
- Can only be called by contract administrator

### Member Functions

#### `join-pool`
- Allows new members to join the pool
- Fails if:
  - Pool is full
  - Caller is already a member

#### `contribute`
- Allows members to make their contribution for the current round
- Requires exact contribution amount in STX
- Prevents double contributions in the same round

#### `withdraw`
- Allows the designated beneficiary to withdraw funds
- Can only be called by the selected recipient for the round
- Transfers entire pool balance to recipient

### Administrative Functions

#### `select-distribution-recipient`
- Selects the next recipient for fund distribution
- Currently uses a placeholder selection mechanism
- Can only be called by contract administrator

### Read-Only Functions

#### `get-participant-info`
- Parameters:
  - `participant`: Principal address to query
- Returns participant's membership status and contribution history

#### `get-pool-status`
- Returns current pool statistics:
  - Current round number
  - Total balance
  - Participant limit
  - Required contribution amount
  - Current number of participants

## Error Codes

- `ERR-UNAUTHORIZED (u1)`: Caller lacks required permissions
- `ERR-INSUFFICIENT-BALANCE (u2)`: Insufficient funds for operation
- `ERR-MEMBER-EXISTS (u3)`: Member already exists in pool
- `ERR-MEMBER-NOT-FOUND (u4)`: Member not found in pool
- `ERR-CYCLE-INCOMPLETE (u5)`: Current cycle is incomplete
- `ERR-WITHDRAWAL-INVALID (u6)`: Invalid withdrawal attempt
- `ERR-INVALID-PARTICIPANT-LIMIT (u7)`: Invalid participant limit specified
- `ERR-INVALID-CONTRIBUTION-AMOUNT (u8)`: Invalid contribution amount specified

## Security Considerations

1. **Input Validation**
   - Participant limits are strictly enforced
   - Contribution amounts are validated
   - Member status is verified for all operations

2. **Access Control**
   - Administrative functions restricted to contract owner
   - Withdrawal restricted to designated beneficiary
   - Double contributions prevented

3. **Known Limitations**
   - Simplified recipient selection mechanism
   - No built-in dispute resolution
   - Fixed contribution amounts

## Future Improvements

1. Implement robust randomness for recipient selection
2. Add support for variable contribution amounts
3. Include dispute resolution mechanism
4. Add member reputation system
5. Implement emergency pause functionality
6. Add support for multiple pools
