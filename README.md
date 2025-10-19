🧠 Memory-Loss DAO

Version: 1.0.0

Summary: A DAO with anti-hoarding governance — proposals auto-erase weekly

📖 Description

Memory-Loss DAO is a minimalistic and experimental Decentralized Autonomous Organization (DAO) built in Clarity. It introduces a self-cleaning governance mechanism that automatically deletes proposals older than one week (measured in block height). This prevents long-term proposal hoarding, enforces timely community participation, and keeps governance agile.

⚙️ Key Features

Ephemeral Proposals:
Proposals older than BLOCKS_PER_WEEK (~7 days) are permanently erased.

Stake-based Membership:
Users join by staking tokens (tracked by the contract), which defines their voting power.

Weighted Voting:
Voting power corresponds directly to each member’s stake amount.

Proposal Lifecycle Management:
Expired proposals cannot be voted on or retrieved via get-proposal.

Automatic Erasure Routine:
Anyone can trigger erase-old-proposals() to clean up proposals older than a week.

🧩 Contract Components
Constants
Constant	Description
ERR_UNAUTHORIZED	Unauthorized caller (401)
ERR_PROPOSAL_NOT_FOUND	Proposal not found (404)
ERR_PROPOSAL_EXPIRED	Proposal expired (410)
ERR_INVALID_VOTES	Invalid vote input (400)
BLOCKS_PER_WEEK	Number of blocks representing ~7 days (u1008)

Data Variables
Variable	Type	Description
next-proposal-id	uint	Tracks next proposal ID
dao-treasury	uint	Total DAO treasury (sum of stakes)
Maps
Map	Key	Value	Description
proposals	uint	Proposal details (title, proposer, votes, etc.)	
member-votes	{proposal-id, voter}	Record of individual votes	
dao-members	principal	Member stake amount	

🔐 Public Functions
join-dao (stake-amount uint)

Join the DAO by staking tokens.

Preconditions: stake-amount > 0

Effects: Adds sender to dao-members and increases DAO treasury.

Returns: (ok true)

create-proposal (title string, description string)

Create a new governance proposal.

Preconditions: Must be a DAO member; valid title & description.

Effects: Stores proposal in proposals map and increments proposal ID.

Returns: (ok proposal-id)

vote-proposal (proposal-id uint, vote-for bool)

Vote for or against a proposal based on your stake.

Preconditions:

Proposal must exist.

Must be a DAO member.

Proposal must not be expired.

Effects:

Records vote in member-votes.

Adds weighted stake to either votes-for or votes-against.

Returns: (ok true)

erase-old-proposals ()

Remove all proposals older than BLOCKS_PER_WEEK.

Callable by anyone.

Returns: (ok u0) (accumulator placeholder).

🔍 Read-Only Functions
Function	Description
get-proposal (proposal-id)	Returns proposal details if still valid (not expired).
get-dao-member (member)	Returns a member’s stake, if any.
get-treasury-balance ()	Returns total DAO treasury.
get-next-proposal-id ()	Returns the next available proposal ID.

🧹 Private Function
erase-proposal-if-old (proposal-id, acc)

Helper function used internally by erase-old-proposals to check each proposal’s age and delete expired ones.

⏳ Lifecycle Example

Alice joins the DAO:

(contract-call? .memory-loss-dao join-dao u100)


Alice creates a proposal:

(contract-call? .memory-loss-dao create-proposal "New Treasury Plan" "Proposal to allocate funds for audits.")


Bob joins and votes:

(contract-call? .memory-loss-dao vote-proposal u1 true)


After one week (1008 blocks):
Proposal expires and is auto-removed by calling:

(contract-call? .memory-loss-dao erase-old-proposals)

⚠️ Notes

This contract doesn’t handle real STX transfers — the stake-amount is logical, not actual token locking.

The erase operation currently runs on a small fixed list of IDs for demonstration; production versions should iterate dynamically.

Overflow protection is handled via assertions.

📝 License
MIT License. Free to use, modify, and extend for DAO governance experimentation.