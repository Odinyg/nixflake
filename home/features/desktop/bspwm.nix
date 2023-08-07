{
  xsession.windowManager.bspwm = {
    enable = true;
    settings = 
      {
        border_width = 2;
	window_gap = 10;
        gapless_monocle = true;
        split_ratio = 0.52;
	remove_disabled_monitors = true;
	remove_unplugged_monitors = true;
	merge_overlapping_monitors = true;
    rules = {
      "Gimp" = {
        desktop = "^8";
        state = "floating";
        follow = true;
      };
      "Kupfer.py" = {
        focus = true;
      };
      "Screenkey" = {
        manage = false;
      };
    }
    startupPrograms = [
      "numlockx on"
      "sxhkd"

    ]
      }   

  }
}
