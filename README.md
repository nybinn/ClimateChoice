# ClimateChoice

ClimateChoice is a community-driven system for environmental project prioritization and impact assessment built on the Stacks blockchain using Clarity smart contracts.

## Overview

ClimateChoice enables communities to submit, vote on, fund, and track environmental projects through a decentralized platform. The system promotes transparency and community engagement in environmental initiatives while providing mechanisms for impact measurement and project accountability.

## Features

- **Project Submission**: Users can submit environmental projects with detailed descriptions, categories, and impact targets
- **Community Voting**: Stakeholders can vote on pending projects to determine community support
- **Project Funding**: Contributors can fund active projects with transparent tracking
- **Impact Tracking**: Project creators can update progress and impact metrics
- **Status Management**: Projects progress through defined stages (pending, active, completed, cancelled)
- **Category Analytics**: Track project distribution and statistics across environmental categories
- **Transparency**: All project data, votes, and contributions are publicly accessible on-chain

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Version**: 1.0.0

### Project Lifecycle

1. **Pending**: Newly submitted projects awaiting community votes
2. **Active**: Approved projects that can receive funding and track impact
3. **Completed**: Successfully finished projects
4. **Cancelled**: Discontinued projects

### Data Structures

#### Project Data
- Title (100 chars max)
- Description (500 chars max, UTF-8)
- Creator principal
- Category (50 chars max)
- Target and current impact metrics
- Voting statistics
- Funding goals and current funding
- Status and timestamps

#### Voting System
- Binary voting (support/oppose)
- One vote per user per project
- Only available for pending projects
- Transparent vote history

#### Funding Mechanism
- Community contributions tracked per user
- Cumulative funding totals
- Only available for active projects

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Stacks CLI](https://docs.stacks.co/build-with-clarity/stacks-cli)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ClimateChoice
```

2. Navigate to the contract directory:
```bash
cd ClimateChoice_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Submit a Project

```clarity
(contract-call? .ClimateChoice submit-project
  "Solar Panel Installation"
  "Install solar panels in rural communities to reduce carbon footprint"
  "renewable-energy"
  u1000  ;; target impact (e.g., kWh generated)
  u50000 ;; funding goal (e.g., microSTX)
)
```

### Vote on a Project

```clarity
;; Vote in favor of project ID 1
(contract-call? .ClimateChoice vote-on-project u1 true)

;; Vote against project ID 1
(contract-call? .ClimateChoice vote-on-project u1 false)
```

### Contribute Funding

```clarity
(contract-call? .ClimateChoice contribute-funding u1 u10000)
```

### Update Project Impact

```clarity
;; Project creator updates current impact
(contract-call? .ClimateChoice update-impact u1 u250)
```

## Contract Functions

### Public Functions

#### `submit-project`
Submit a new environmental project for community consideration.

**Parameters:**
- `title` (string-ascii 100): Project title
- `description` (string-utf8 500): Detailed project description
- `category` (string-ascii 50): Environmental category
- `target-impact` (uint): Target impact metric
- `funding-goal` (uint): Required funding amount

**Returns:** Project ID on success

#### `vote-on-project`
Cast a vote on a pending project.

**Parameters:**
- `project-id` (uint): Target project identifier
- `vote` (bool): true for support, false for opposition

**Restrictions:** One vote per user per project, pending projects only

#### `activate-project`
Activate a pending project (contract owner only).

**Parameters:**
- `project-id` (uint): Project to activate

**Restrictions:** Contract owner only, pending projects only

#### `update-impact`
Update current impact metrics (project creator only).

**Parameters:**
- `project-id` (uint): Target project
- `new-impact` (uint): Updated impact value

**Restrictions:** Project creator only, active projects only

#### `contribute-funding`
Contribute funding to an active project.

**Parameters:**
- `project-id` (uint): Target project
- `amount` (uint): Contribution amount

**Restrictions:** Active projects only

#### `complete-project`
Mark a project as completed (project creator only).

**Parameters:**
- `project-id` (uint): Project to complete

**Restrictions:** Project creator only, active projects only

### Read-Only Functions

#### `get-project`
Retrieve complete project information.

#### `get-user-vote`
Get a user's vote on a specific project.

#### `get-user-contribution`
Get a user's contribution amount to a project.

#### `get-category-stats`
Retrieve statistics for a project category.

#### `get-total-projects`
Get the total number of submitted projects.

#### `is-funding-goal-reached`
Check if a project has reached its funding goal.

#### `get-impact-completion-percentage`
Calculate project completion percentage based on impact metrics.

#### `get-project-support-percentage`
Calculate community support percentage for a project.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy and interact with the contract in the REPL:
```clarity
::deploy_contract ClimateChoice
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Testing

Run the test suite:

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

## Security Considerations

### Access Controls
- **Contract Owner**: Can activate pending projects
- **Project Creators**: Can update impact metrics and complete their projects
- **Community Members**: Can vote on pending projects and fund active projects

### Validation Checks
- Prevents double voting on projects
- Validates project status for operations
- Ensures only authorized users can modify project data
- Checks project existence before operations

### Error Handling
The contract implements comprehensive error codes:
- `u100`: Owner-only operation attempted by non-owner
- `u101`: Project not found
- `u102`: Unauthorized operation
- `u103`: User already voted on project
- `u104`: Invalid project status for operation
- `u105`: Project not in active status

### Best Practices
- All state changes are atomic
- Input validation prevents invalid data
- Clear separation of concerns between different user roles
- Transparent operation history through blockchain records

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with appropriate tests
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions or issues, please open an issue on the project repository or contact the development team.