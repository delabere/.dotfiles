{ pkgs, lib, ... }:

let
  terminus-image = "ghcr.io/usetrmnl/terminus:latest";
  
  common-env = {
    "API_URI" = "http://192.168.1.11:2300";
    "APP_SECRET" = "4675543666d62524d775150587a324b3337774c53443372674e5033703058444a4969376175647563574d6e4b47636e614666353935393566675038676239326e";
    "DATABASE_URL" = "postgres://terminus:supersecret@database:5432/terminus_production";
    "HANAMI_PORT" = "2300";
    "KEYVALUE_URL" = "redis://:redis_secret@keyvalue:6379/0";
  };

  common-volumes = [
    "terminus_certificates:/etc/ssl/certs:rw"
    "terminus_web-uploads:/app/public/uploads:rw"
  ];

  # Helper to create volume/network setup services
  mkDockerRes = type: name: {
    path = [ pkgs.docker ];
    serviceConfig.Type = "oneshot";
    script = "docker ${type} inspect ${name} || docker ${type} create ${name}";
    partOf = [ "docker-compose-terminus-root.target" ];
    wantedBy = [ "docker-compose-terminus-root.target" ];
  };

  volumes = [
    "terminus_certificates"
    "terminus_database-data"
    "terminus_keyvalue-data"
    "terminus_web-uploads"
  ];
in
{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers = {
    "terminus-database" = {
      image = "postgres:18.3-alpine";
      environment = {
        "POSTGRES_DB" = "terminus_production";
        "POSTGRES_PASSWORD" = "supersecret";
        "POSTGRES_USER" = "terminus";
      };
      volumes = [ "terminus_database-data:/var/lib/postgresql:rw" ];
      ports = [ "5432:5432/tcp" ];
      cmd = [ "-p" "5432" ];
      extraOptions = [
        "--cpus=1"
        "--memory=2G"
        "--health-cmd=pg_isready --username terminus --dbname terminus_production --port 5432"
        "--network=terminus_default"
        "--network-alias=database"
      ];
    };

    "terminus-keyvalue" = {
      image = "valkey/valkey:9-alpine";
      volumes = [ "terminus_keyvalue-data:/data:rw" ];
      ports = [ "6379:6379/tcp" ];
      cmd = [ "valkey-server" "--requirepass" "redis_secret" "--maxmemory" "512mb" "--maxmemory-policy" "noeviction" "--port" "6379" ];
      extraOptions = [
        "--cpus=0.5"
        "--memory=512M"
        "--health-cmd=redis-cli -p 6379 ping || exit 1"
        "--network=terminus_default"
        "--network-alias=keyvalue"
      ];
    };

    "terminus-init-certificates" = {
      image = terminus-image;
      cmd = [ "scripts/docker/install-certificates" ];
      volumes = [ "terminus_certificates:/etc/ssl/certs:rw" ];
      extraOptions = [
        "--entrypoint=/bin/bash"
        "--network=terminus_default"
      ];
    };

    "terminus-web" = {
      image = terminus-image;
      environment = common-env // { "APP_SETUP" = "true"; };
      volumes = common-volumes;
      ports = [ "2300:2300/tcp" ];
      dependsOn = [
        "terminus-database"
        "terminus-keyvalue"
        "terminus-init-certificates"
      ];
      extraOptions = [
        "--cpus=1"
        "--memory=1G"
        "--init"
        "--health-cmd=curl --fail --silent http://localhost:2300/up"
        "--network=terminus_default"
        "--network-alias=web"
      ];
    };

    "terminus-worker" = {
      image = terminus-image;
      environment = common-env;
      volumes = common-volumes;
      cmd = [ "bundle" "exec" "sidekiq" "-r" "./config/sidekiq.rb" ];
      dependsOn = [ "terminus-web" ];
      extraOptions = [
        "--cpus=1"
        "--memory=1G"
        "--init"
        "--health-cmd=pgrep -f sidekiq"
        "--network=terminus_default"
        "--network-alias=worker"
      ];
    };
  };

  # Network and Volume resources + container dependencies
  systemd.services = let
    resDeps = [ "docker-network-terminus_default.service" ] 
              ++ (map (v: "docker-volume-${v}.service") volumes);
  in (lib.listToAttrs (map (v: lib.nameValuePair "docker-volume-${v}" (mkDockerRes "volume" v)) volumes)) // {
    "docker-network-terminus_default" = mkDockerRes "network" "terminus_default";
    
    # Ensure containers wait for resources
    "docker-terminus-database" = { after = resDeps; requires = resDeps; };
    "docker-terminus-keyvalue" = { after = resDeps; requires = resDeps; };
    "docker-terminus-web" = { after = resDeps; requires = resDeps; };
    "docker-terminus-worker" = { after = resDeps; requires = resDeps; };
    
    "docker-terminus-init-certificates" = {
      after = resDeps;
      requires = resDeps;
      serviceConfig.Restart = lib.mkOverride 90 "no";
    };
  };

  systemd.targets."docker-compose-terminus-root" = {
    unitConfig.Description = "Terminus Stack";
    wantedBy = [ "multi-user.target" ];
  };
}
