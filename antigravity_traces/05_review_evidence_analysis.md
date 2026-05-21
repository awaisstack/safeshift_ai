# Review Evidence Analysis

- **Agent Name**: Review Evidence Summary Agent
- **Status**: Verified

## Agent Trace Details

- **Observation**: 5 candidate providers have review history in the curated public-source registry.
- **Inference**: Reviews are synthetic MVP samples. Budget Loaderz has severe negative complaints about hidden charges and broken fragile lamps.
- **Decision**: Raise high-risk flag for Budget Loaderz and minor-risk flag for Zain Packers.
- **Tool Call**: `ReviewEvidenceTool.analyzeReviews(providerIds: ["p1", "p2", "p3", "p4", "p5"])`
- **Tool Result**: `{p1: {trust: 95%, flags: []}, p2: {trust: 90%, flags: []}, p3: {trust: 82%, flags: [fragile_scratch]}, p4: {trust: 80%, flags: []}, p5: {trust: 40%, flags: [hidden_charges, fragile_broken, punctuality]}}`
- **Action**: Extract risk profiles for each provider and send to Matcher & Ranker Agent.
- **Outcome**: Flagged Budget Loaderz as high-risk due to clear patterns of hidden stair surcharges.
