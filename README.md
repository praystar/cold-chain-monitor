# Temperature Control Smart Contract

A Clarity smart contract for monitoring temperature-sensitive goods throughout the cold chain supply process, ensuring quality maintenance from origin to consumer.

## Overview

This smart contract provides comprehensive tracking and monitoring for temperature-sensitive products like pharmaceuticals, vaccines, fresh produce, and other perishable goods. It maintains an immutable record of temperature data, custody transfers, and quality assessments on the Stacks blockchain.

## Features

### 🌡️ Temperature Monitoring
- Real-time temperature logging with timestamps
- Automatic breach detection and quality scoring
- Configurable temperature ranges per shipment
- Historical temperature data storage

### 📦 Shipment Tracking
- End-to-end shipment lifecycle management
- Custody transfer between handlers
- Origin to destination tracking
- Real-time status updates

### 🔒 Security & Authorization
- Multi-level authorization system
- Handler verification
- Secure custody transfers
- Emergency reporting capabilities

### 📊 Quality Assurance
- Dynamic quality scoring (0-100)
- Automated breach counting
- Quality assessment categories
- Compliance verification

## Project Structure

```
temperaturecontrol/
├── contracts/
│   └── tempcontrol.clar          # Main smart contract
├── deployments/
│   └── default.testnet-plan.yaml # Deployment configuration
├── tests/                        # Test files
├── .cache/                       # Clarinet cache
└── Clarinet.toml                 # Project configuration
```

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks testnet wallet (for deployment)

### Project Demo and Contract Address

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd temperaturecontrol
```

2. Verify project setup:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

### Deployment

#### Testnet Deployment

1. Generate deployment plan:
```bash
clarinet deployments generate
```

2. Deploy to testnet:
```bash
clarinet deployments apply
```

3. Verify deployment:
```bash
clarinet console
```

#### Mainnet Deployment

1. Update deployment configuration for mainnet
2. Ensure sufficient STX for deployment fees
3. Deploy using production keys

## Smart Contract Functions

### Public Functions

#### Shipment Management
- `create-shipment`: Initialize new temperature-monitored shipment
- `transfer-custody`: Transfer shipment between handlers
- `complete-delivery`: Mark shipment as delivered
- `report-emergency`: Report emergency situations

#### Temperature Logging
- `log-temperature`: Record temperature reading with metadata
- `add-authorized-handler`: Add authorized temperature logger
- `remove-authorized-handler`: Remove handler authorization

### Read-Only Functions

#### Data Retrieval
- `get-shipment`: Retrieve shipment details
- `get-temperature-log`: Get specific temperature log entry
- `get-shipment-status`: Get current shipment status
- `get-quality-assessment`: Get quality score and assessment

#### Compliance Checks
- `is-temperature-compliant`: Check current temperature compliance
- `is-authorized-handler`: Verify handler authorization

## Usage Examples

### Creating a Shipment

```clarity
(contract-call? .tempcontrol create-shipment 
  "SHIPMENT-001" 
  'ST1DESTINATION... 
  "Vaccines" 
  2    ;; min temp (°C)
  8    ;; max temp (°C)
  5)   ;; initial temp (°C)
```

### Logging Temperature

```clarity
(contract-call? .tempcontrol log-temperature
  "SHIPMENT-001"
  4              ;; temperature (°C)
  "Warehouse-A"  ;; location
  "SENSOR-123")  ;; sensor ID
```

### Checking Quality

```clarity
(contract-call? .tempcontrol get-quality-assessment "SHIPMENT-001")
;; Returns: {quality-score: u95, temperature-breaches: u0, status: "in-transit", assessment: "excellent"}
```

## Data Structures

### Shipment Record
```clarity
{
  origin: principal,
  destination: principal,
  current-handler: principal,
  product-type: (string-ascii 100),
  min-temp: int,
  max-temp: int,
  current-temp: int,
  status: (string-ascii 20),
  created-at: uint,
  updated-at: uint,
  temperature-breaches: uint,
  quality-score: uint
}
```

### Temperature Log
```clarity
{
  temperature: int,
  timestamp: uint,
  location: (string-ascii 100),
  handler: principal,
  sensor-id: (string-ascii 50)
}
```

## Quality Scoring System

| Quality Score | Assessment | Description |
|---------------|------------|-------------|
| 80-100        | Excellent  | No significant temperature breaches |
| 60-79         | Good       | Minor temperature deviations |
| 40-59         | Fair       | Some temperature breaches occurred |
| 0-39          | Poor       | Multiple or severe temperature breaches |

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u401 | NOT_AUTHORIZED | Caller not authorized for this operation |
| u404 | SHIPMENT_NOT_FOUND | Shipment ID does not exist |
| u400 | INVALID_TEMPERATURE | Temperature values are invalid |
| u409 | SHIPMENT_ALREADY_EXISTS | Shipment ID already in use |
| u410 | SHIPMENT_COMPLETED | Operation not allowed on completed shipment |
| u411 | TEMPERATURE_BREACH | Temperature outside acceptable range |

## Testing

### Unit Tests
```bash
clarinet test
```

### Integration Tests
```bash
clarinet console
::get_contracts_interfaces
```

### Manual Testing
Use the Clarinet console to interact with contract functions:
```bash
clarinet console
>> (contract-call? .tempcontrol create-shipment ...)
```

## Configuration

### Clarinet.toml Settings

```toml
[repl.analysis]
passes = ["check_checker"]
check_checker = { 
  trusted_sender = false,     # Maximum security
  trusted_caller = false,     # Requires explicit validation
  callee_filter = false       # Strict input validation
}
```

These security settings ensure maximum protection for temperature data integrity.

## Use Cases

### Pharmaceutical Supply Chain
- Vaccine cold chain monitoring
- Medicine temperature compliance
- Regulatory compliance tracking

### Food Industry
- Fresh produce monitoring
- Frozen food logistics
- Quality assurance documentation

### Healthcare
- Blood product transport
- Organ transplant logistics
- Medical sample integrity

## Contributing

1. Fork the repository
2. Create feature branch
3. Write comprehensive tests
4. Submit pull request

## Security Considerations

- All temperature data is immutable once recorded
- Only authorized handlers can log temperatures
- Custody transfers require proper authorization
- Emergency reporting available for critical situations

## License

[Add your license information here]

## Support

For questions or support:
- Create an issue in the repository
- Check [Stacks documentation](https://docs.stacks.co/)
- Visit [Clarinet documentation](https://docs.hiro.so/)

## Roadmap

- [ ] Mobile app integration
- [ ] IoT sensor APIs
- [ ] Advanced analytics dashboard
- [ ] Multi-chain support
- [ ] Automated compliance reporting

---

Built with ❄️ for the cold chain industry using Clarity smart contracts on Stacks blockchain.
