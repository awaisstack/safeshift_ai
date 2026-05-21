# Failure Recovery

- **Agent Name**: Recovery Agent
- **Status**: Simulated

## Agent Trace Details

- **Observation**: Original driver from Reliable Packers reported delayed by 45 minutes.
- **Inference**: High risk of violating user arrival constraint. Dynamic recovery protocol required.
- **Decision**: Search local provider dataset for active backups in service zone.
- **Tool Call**: `RecoveryPlanner.findActiveBackups(zone: "Islamabad", originalMoverId: "p1")`
- **Tool Result**: `{backups_found: 2, candidates: ["Costa Logistics", "Zain Packers"]}`
- **Action**: Offer user switch options with a PKR 500 delay rebate compensation.
- **Outcome**: Immediate switch panel rendered for user selection.
