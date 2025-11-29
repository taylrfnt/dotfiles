{
  pkgs,
  # lib,
  ...
}: {
  enable = true;
  package = pkgs.opencode;
  settings = {
    theme = "system";
    provider = {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "qwen2.5-coder" = {
            name = "Qwen2.5 Coder";
          };
          "qwen3-coder" = {
            name = "Qwen 3 Coder (30B)";
          };
          # distills are broken right now - https://github.com/ollama/ollama/issues/8517
          # "deepseek-coder-v2" = {
          #   name = "Deepseek Coder v2";
          # };
        };
      };
    };
  };
}
