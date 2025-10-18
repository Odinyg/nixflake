{
  vim = "nvim";
  dcpshow = "docker ps --format '{{.Names}}'\t'{{.Ports}}'";
  sshmain = "ssh -Y $server";
  v = "nvim";
  sv = "sudo nvim";
  grep = "grep --color=auto";
  psgrep = "ps aux | grep -v grep | grep -i -e VSZ -e";
  workvpn = "sudo openvpn --config /root/vpn.ovpn --auth-user-pass /root/pass --allow-compression asym";
  telreset = "/usr/bin/telreset";
  cat = "bat";
  k = "kubectl";
  kg = "kubectl get";
  cd = "z";
}
