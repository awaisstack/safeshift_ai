class AgentTrace {
  final String stepName;
  final String observation;
  final String inference;
  final String decision;
  final String? toolCall;
  final String? toolResult;
  final String action;
  final String? fallback;
  final String outcome;

  AgentTrace({
    required this.stepName,
    required this.observation,
    required this.inference,
    required this.decision,
    this.toolCall,
    this.toolResult,
    required this.action,
    this.fallback,
    required this.outcome,
  });
}
