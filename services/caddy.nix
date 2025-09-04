{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;
    virtualHosts."www.delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3002
    '';
    virtualHosts."delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3002
    '';
    virtualHosts."wubalubadubdub.delabere.com".extraConfig = ''
      respond "Hello, world wubalubadubdub!!"
    '';
    virtualHosts."n8n.delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:5678

    ''; # n8n port
    virtualHosts."breathe.delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3001
    '';
    virtualHosts."property-pulse.delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3003
    '';
    virtualHosts."pulse.delabere.com".extraConfig = ''
      reverse_proxy 127.0.0.1:3003
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

}
#
# services.caddy = {
#   enable = true;
#   # Optional: your global Caddy options
#   # globalConfig = {
#   #   email = "jack.rickards@hotmail.co.uk"; # For Let's Encrypt notifications
#   # };
#   virtualHosts."localhost".extraConfig = ''
#     respond "Hello, world!"
#   '';
# # Define the virtual hosts
# virtualHosts = {
#   # This is your existing main domain configuration (as an example)
#   "delabere.com" = {
#     # Optional: extra configuration for the main domain
#     extraConfig = ''
#       root * /var/www/yourdomain.com
#       file_server
#     '';
#   };

# # --- Add your new subdomain configuration here ---
# "blog.yourdomain.com" = {
#   # This section uses the Caddyfile format
#   extraConfig = ''
#     # Set the root directory for your subdomain's files
#     root * /var/www/blog.yourdomain.com
#
#     # Enable the static file server
#     file_server
#   '';
# };

# You can add more subdomains by creating new entries
# "wiki.yourdomain.com" = { ... };

# };

# ... other NixOS configurations ...
