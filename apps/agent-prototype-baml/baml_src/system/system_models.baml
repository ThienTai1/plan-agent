// enum Agent{
//   PLANER @description(#"
//     the one in charge of plan or set up the goal
//   "#)
//   SCHEDULER @description(#"
//     the one in charge of plan or set up the calendar
//   "#)
// }

// class OrchestratorOutput{
//   assign Agent
//   messages Messages[]
// }


class Messages{
  role "system" | "user" | "assistant"
  content string
}

class Context{
  user_info string?
  current_time string
}

function MyFunction(input: string) -> string {
  client QwenClient
  prompt #"
    {{ _.role("user") }} {{ input }}
  "#
}

test TestQwen {
  functions [MyFunction]
  args {
    input "hello"
  }
}