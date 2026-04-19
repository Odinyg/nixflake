{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;

      devShells.homelab = pkgs.mkShell {
        packages = with pkgs; [
          colmena
          sops
          age
          ssh-to-age
          nixos-anywhere
          nil
          nixfmt-rfc-style
          gitleaks
        ];
      };
    };
}
