{
services.gammastep = {
  enable = true;
  provider = "manual";
  latitude = 61.9;
  longitude = 6.5;
  settings = {

    general = {
      brightness=0.9;
      brightness-day=0.9;
      brightness-night=0.7;
      gamma=0.8;
      gamma-day=0.8;
      gamma-night=0.7;
      adjustment-method = "randr";
    };
    randr = {
      screen = 0;
  };
};
  };
}
