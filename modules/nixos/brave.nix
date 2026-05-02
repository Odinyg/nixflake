{ lib, config, ... }:
let
  cfg = config.brave;
  updateUrl = "https://clients2.google.com/service/update2/crx";
  extensions = [
    "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
    "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
    "khncfooichmfjbepaaaebmommgaepoid" # Unhook — Remove YouTube Recommended & Shorts
    "ijaabbaphikljkkcbgpbaljfjpflpeoo" # Favicon Switcher
    "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
  ];
in
{
  options.brave.enable = lib.mkEnableOption "Brave browser policy + extension management";

  config = lib.mkIf cfg.enable {
    environment.etc."brave/policies/managed/extensions.json".text = builtins.toJSON {
      ExtensionInstallForcelist = map (id: "${id};${updateUrl}") extensions;
      BraveAIChatEnabled = false;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveRewardsDisabled = true;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
    };
  };
}
