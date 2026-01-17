_: {
  conform-nvim = {
    enable = true;
    setupOpts = {
      formatters = {
        mbake = {
          command = "mbake";
          args = [
            "format"
            "--stdin"
          ];
        };
      };
      formatters_by_ft = {
        # everything should go through codespell
        "*" = [
          "codespell"
          "typos"
        ];
        nix = [
          "alejandra"
        ];
        lua = [
          "stylua"
        ];
        go = [
          "goimports"
          "gofumpt"
        ];
        markdown = [
          "deno_fmt"
        ];
        javascript = [
          "deno_fmt"
        ];
        javascriptreact = [
          "deno_fmt"
        ];
        typescript = [
          "deno_fmt"
        ];
        typescriptreact = [
          "deno_fmt"
        ];
        css = [
          "deno_fmt"
        ];
        html = [
          "deno_fmt"
        ];
        yaml = [
          "deno_fmt"
        ];
        json = [
          "deno_fmt"
        ];
        java = [
          "google-java-format"
        ];
        bash = [
          "shellharden"
          "shellcheck"
        ];
        sql = [
          "sqruff"
        ];
        python = [
          "black"
        ];
        # TODO: npm-groovy-lint isn't nix-packaged yet
        # groovy = [
        #   "npm-groovy-lint"
        # ];
        make = [
          "mbake"
        ];
      };
    };
  };
}
