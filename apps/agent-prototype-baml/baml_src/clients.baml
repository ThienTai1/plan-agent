// This model has thinking capability (too expensive to use)
client Gemini31FlashLite {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemini-3.1-flash-lite"
  }
}

client Gemini31Flash {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemini-3.1-flash"
  }
}

client Gemini25Flash {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemini-2.5-flash"
  }
}

client Gemini25FlashLite {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemini-2.5-flash-lite"
  }
}

client Gemini20Flash {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemini-2.0-flash"
  }
}

client Gemma4 {
  provider "google-ai"
  options {
    api_key env.GEMINI_API_KEY
    model "gemma-4"
  }
}

client OpenAI5Nano {
  provider "openai"
  options {
    api_key env.OPENAI_API_KEY
    model "gpt-5-nano"
    // reasoning_effort "none"
  }
}

client OpenAI54Nano {
  provider "openai"
  options {
    api_key env.OPENAI_API_KEY
    model "gpt-5.4-nano"
    // reasoning_effort "minimal"
  }
}

client OpenAI4oMini {
  provider "openai"
  options {
    api_key env.OPENAI_API_KEY
    model "gpt-4o-mini"
  }
}

client<llm> QwenClient {
  provider openrouter
  options {
    model "qwen/qwen3-max"
    api_key env.OPENROUTER_API_KEY
  }
}


// Use for normal case
client FallbackClient {
  provider fallback
  options {
    // strategy [OpenAI4oMini, Gemini25FlashLite, Gemini31FlashLite, Gemini20Flash, OpenAI54Nano]
    strategy [QwenClient]

  }
}

// Use for QC case
client LLMAsJudgeClient {
  provider fallback
  options {
    strategy [Gemini31FlashLite, Gemini31Flash, Gemini25Flash]
  }
}

// client<llm> OpenaiFallback {
//   provider fallback
//   options {
//     // This will try the clients in order until one succeeds
//     strategy [Gemini20FlashLiteLLM, Gemini25FlashLiteLLM, Gemini25FlashLiteLiteLLM]
//   }
// }

retry_policy Constant {
  max_retries 3
  strategy {
    type constant_delay
    delay_ms 200
  }
}

retry_policy Exponential {
  max_retries 2
  strategy {
    type exponential_backoff
    delay_ms 300
    multiplier 1.5
    max_delay_ms 10000
  }
}

