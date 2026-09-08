{ config, ... }:

let
  # Pin the stable CPU multi-architecture image so rebuilds are reproducible.
  minuspodImage = "ttlequals0/minuspod@sha256:7ee972c7b0f993f6967cd09e80a277008edda6fe9f8020a0951138b93150537e";
in
{
  age.secrets.minuspod-env = {
    file = ./../secrets/minuspod-env.age;
  };

  virtualisation.oci-containers.containers.minuspod = {
    image = minuspodImage;
    autoStart = true;
    environmentFiles = [ config.age.secrets.minuspod-env.path ];
    environment = {
      # Podcast clients must be able to fetch generated RSS and enclosures
      # without joining the tailnet. Keep management links on Tailscale.
      BASE_URL = "https://podcasts.delabere.com";
      UI_BASE_URL = "https://brain.degu-vega.ts.net:8443";
      MINUSPOD_ENABLE_HSTS = "true";
      MINUSPOD_PORT = "8000";
      MINUSPOD_TRUSTED_PROXY_COUNT = "1";
      OMP_NUM_THREADS = "6";
      SESSION_COOKIE_SECURE = "true";
      TZ = config.time.timeZone;
      WHISPER_DEVICE = "cpu";
      WHISPER_MODEL = "tiny";
    };
    ports = [ "127.0.0.1:8000:8000" ];
    volumes = [ "/data/.state/minuspod:/app/data:rw" ];
    extraOptions = [
      "--cpus=6"
      "--memory=10g"
      "--pids-limit=512"
      "--user=1000:1000"
      "--init"
      "--security-opt=no-new-privileges:true"
      "--cap-drop=ALL"
      "--health-cmd=curl -fsS http://127.0.0.1:8000/api/v1/health || exit 1"
      "--health-interval=30s"
      "--health-timeout=5s"
      "--health-retries=3"
      "--health-start-period=30s"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data/.state/minuspod 0750 delabere media -"
  ];

  # Keep background transcription behind interactive services and Tdarr.
  systemd.services.docker-minuspod.serviceConfig = {
    CPUWeight = 10;
    Nice = 10;
  };
}
