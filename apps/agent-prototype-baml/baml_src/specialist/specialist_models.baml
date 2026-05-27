// ══════════════════════════════════════════════════════════════════════
// SPECIALIST MODELS
// ══════════════════════════════════════════════════════════════════════

enum BlueprintStatus {
    READY_TO_PLAN @description(#"The user's request requires modifying data or fetching specific records from the system."#)
    ALREADY_DONE @description(#"The user's request has already been achieved based on the conversation history."#)
}

class Blueprint {
    objective string @description("The overarching goal the user wants to achieve.")
    thought string? @description("Expert reasoning or clarifications that help the Planner understand why certain constraints exist.")
}

class SpecialistInput {
    query string
    context string
    history Messages[]
}
