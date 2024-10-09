{
  nixb = "sudo nixos-rebuild boot --flake ~/nixflake/#myNixos";
  nixs = "sudo nixos-rebuild switch --flake ~/nixflake/#myNixos";
  vim = "nvim";
  dcpshow = "docker ps --format '{{.Names}}'\t'{{.Ports}}'";
  sshmain = "ssh -Y $server";
  v = "nvim";
  grep = "grep --color=auto";
  psgrep = "ps aux | grep -v grep | grep -i -e VSZ -e";
  workvpn = "sudo openvpn --config /root/vpn.ovpn --auth-user-pass /root/pass --allow-compression asym";
  telreset = "/usr/bin/telreset";
  cat = "bat";
}
