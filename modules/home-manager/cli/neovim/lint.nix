{
  programs.nixvim = {
      plugins.lint = {
        enable = true;
        lintersByFt = {
          json = [ "jsonlint" ];
          rst = [ "vale" ];
          ruby = [ "ruby" ];
          janet = [ "janet" ];
          inko = [ "inko" ];
          clojure = [ "clj-kondo" ];
          dockerfile = [ "hadolint" ];
          terraform = [ "tflint" ];
          nix = [ "nix" ];
        };
      };
      };
    }
