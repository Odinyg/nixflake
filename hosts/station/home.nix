{
  imports = [
  #../../home/features/cli/neovim	
  #../../home/features/cli	
  ];



  nixpkgs.config.allowUnfree = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "none";
    homeDirectory = "/home/none";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  # Load the pulseaudio module that enables sharing audio devices with computers on the network.
}
