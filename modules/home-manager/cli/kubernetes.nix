{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.kubernetes;
in
{
  options = {
    kubernetes = {
      enable = lib.mkEnableOption "Kubernetes CLI tools";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      k9s # Kubernetes TUI
      kubectx # Switch between clusters/namespaces
      fluxcd # GitOps toolkit
      kubernetes-helm # Package manager for Kubernetes
      kubernetes # Kubernetes CLI (kubectl)
      talosctl # Talos Linux CLI
      rke2 # Rancher Kubernetes Engine 2
    ];

    # Kubernetes shell aliases
    home.shellAliases = {
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
      kga = "kubectl get all";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgd = "kubectl get deployments";
    };
  };
}
