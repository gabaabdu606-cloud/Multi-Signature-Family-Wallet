# 👨‍👩‍👧‍👦 Multi-Signature Family Wallet

A secure Clarity smart contract that enables families to jointly manage their digital assets with multi-signature approval for large transactions.

## 🎯 Features

- 👥 **Family Member Management**: Parents can add/remove children and family members
- 💰 **Smart Spending Control**: Automatic approval for small amounts, multi-sig for large transactions  
- 🗳️ **Democratic Voting**: Family members vote to approve significant expenses
- 🚨 **Emergency Withdrawal**: Parents have emergency access to limited funds (max 10% of balance)
- ⚡ **Flexible Thresholds**: Customizable spending limits for different approval requirements

## 🚀 Getting Started

### Installation

```bash
clarinet new family-wallet
cd family-wallet
```

Copy the contract code into `contracts/Multi-Signature-Family-Wallet.clar`

### 📋 Usage

#### Initialize the Wallet
```clarity
(contract-call? .Multi-Signature-Family-Wallet initialize 
  (list 'SP1234... 'SP5678...)  ; family members
  (list "parent" "child"))       ; their roles
```

#### Add Family Members 👪
```clarity
(contract-call? .Multi-Signature-Family-Wallet add-family-member 'SP9ABC... "child")
```

#### Deposit Funds 💳
```clarity
(contract-call? .Multi-Signature-Family-Wallet deposit)
```

#### Set Spending Threshold 🎚️
```clarity
(contract-call? .Multi-Signature-Family-Wallet set-spending-threshold u5000000) ; 5 STX
```

#### Propose Transaction 📝
```clarity
(contract-call? .Multi-Signature-Family-Wallet propose-transaction 'SP-RECIPIENT... u2000000)
```

#### Vote on Transaction 🗳️
```clarity
(contract-call? .Multi-Signature-Family-Wallet vote-transaction u1)
```

## 🔒 Security Features

- **Role-Based Access**: Parents have administrative privileges
- **Spending Controls**: Large transactions require family consensus
- **Emergency Safeguards**: Limited emergency withdrawal (10% max)
- **Vote Tracking**: Prevents double voting and ensures transparency

## 📊 Contract Functions

### Read-Only Functions
- `get-balance`: Check wallet balance
- `get-threshold`: View current spending threshold
- `is-family-member`: Verify family membership
- `get-transaction`: View transaction details
- `get-transaction-status`: Check approval status

### Public Functions
- `initialize`: Set up the wallet with initial family members
- `add-family-member`: Add new family member (parents only)
- `remove-family-member`: Remove family member (parents only)
- `set-spending-threshold`: Adjust approval threshold
- `deposit`: Add funds to the wallet
- `propose-transaction`: Create new spending proposal
- `vote-transaction`: Approve/reject transactions
- `emergency-withdraw`: Emergency fund access (parents only)

## 🎮 Example Workflow

1. **Setup**: Parents initialize wallet with family members
2. **Fund**: Family deposits STX tokens
3. **Small Purchase**: Child proposes $20 gaming purchase → Auto-approved ✅
4. **Large Purchase**: Teen proposes $500 laptop → Requires votes from family 🗳️
5. **Emergency**: Parent needs quick access → Uses emergency withdrawal 🚨

## 🛡️ Error Codes

- `u100`: Not authorized
- `u101`: Invalid amount
- `u102`: Insufficient balance
- `u103`: Transaction not found
- `u104`: Already voted
- `u105`: Transaction already executed
- `u106`: Invalid threshold
- `u107`: Member already exists
- `u108`: Member not found

## 🧪 Testing

```bash
clarinet test
```

## 📄 License

MIT License - Feel free to use for your family's financial management! 💼
