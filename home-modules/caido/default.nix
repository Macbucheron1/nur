{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.programs.caido;
  yamlFormat = pkgs.formats.yaml {};

  pluginType = types.either types.str (types.submodule {
    options = {
      store = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Community Store plugin identifier, resolved by Caido at runtime.";
      };
      path = mkOption {
        type = types.nullOr (types.either types.path types.package);
        default = null;
        description = "Local `plugin_package.zip` (Nix path or derivation).";
      };
    };
  });

  normalizePlugin = p:
    if builtins.isString p
    then {store = p;}
    else if (p.store != null) == (p.path != null)
    then throw "programs.caido.settings.plugins: each entry must set exactly one of `store` or `path`."
    else if p.store != null
    then {inherit (p) store;}
    else {path = toString p.path;};

  # Drop unset (null) values, then sections left empty by that.
  prune = v:
    if builtins.isAttrs v
    then lib.filterAttrs (_: x: x != {}) (lib.mapAttrs (_: prune) (lib.filterAttrs (_: x: x != null) v))
    else v;
  clean = prune;

  config' = clean (cfg.settings
    // {
      plugins =
        if cfg.settings.plugins == null
        then null
        else map normalizePlugin cfg.settings.plugins;
    });

  merged = lib.recursiveUpdate config' cfg.extraSettings;

  configFile = yamlFormat.generate "caido.yaml" {
    version = cfg.package.version;
    config = merged;
  };

  opt = type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };
in {
  options.programs.caido = {
    enable = mkEnableOption "declarative management of the Caido YAML configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.caido-cli;
      defaultText = lib.literalExpression "pkgs.caido-cli";
      description = "Caido CLI package; its version is written to the `version` key.";
    };

    configPath = mkOption {
      type = types.str;
      default = "caido/caido.yaml";
      description = "Location of the generated file, relative to `xdg.configHome`.";
    };

    installWrapper = mkOption {
      type = types.bool;
      default = true;
      description = "Install `caido-managed`, running `caido-cli --config` on the generated file.";
    };

    settings = {
      data_path = opt types.str "Directory where Caido stores its data.";

      cloud = {
        registration_key = opt types.str "Workspace registration key (ends up in the Nix store).";
        sync = opt types.bool "Enable cloud sync.";
        reset_cache = opt types.bool "Reset the cloud cache on start.";
        reset_credentials = opt types.bool "Reset cloud credentials on start.";
      };

      security = {
        allow_domains = opt (types.listOf types.str) "Domains allowed to access the instance.";
        allow_guests = opt types.bool "Allow guest access.";
        render_sandbox = opt types.bool "Sandbox the response renderer.";
      };

      networking = {
        listeners = opt (types.listOf (types.submodule {
          options = {
            address = mkOption {
              type = types.str;
              example = "127.0.0.1:8080";
              description = "Address and port to listen on.";
            };
            usage = opt (types.enum ["both" "proxy" "ui"]) "What the listener serves.";
          };
        })) "Network listeners.";
        invisible = opt types.bool "Enable invisible proxying.";
        ca = {
          path = opt types.str "Path to the CA P12 file (prefer a runtime string path).";
          password = opt types.str "CA P12 password (ends up in the Nix store).";
        };
      };

      project = {
        name = opt types.str "Project to open on start.";
        scopes = opt (types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Scope name.";
            };
            allowlist = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Allowed hosts.";
            };
            denylist = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Denied hosts.";
            };
          };
        })) "Project scopes.";
      };

      plugins = opt (types.listOf pluginType) ''
        Plugins to install: a Community Store identifier (string or
        `{ store = ...; }`) or a local package (`{ path = ...; }`).
      '';

      logging = {
        debug = opt types.bool "Enable debug logging.";
        file = opt types.bool "Log to a file.";
      };

      runtime = {
        safe = opt types.bool "Start in safe mode.";
        parent_pid = opt types.int "Exit when this parent PID dies.";
        open_browser = opt types.bool "Open the browser on start.";
      };

      strict = opt types.bool "Fail on unknown or invalid configuration.";
    };

    extraSettings = mkOption {
      type = yamlFormat.type;
      default = {};
      description = "Extra settings recursively merged over `settings` (for new upstream options).";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.settings.project.name == null && cfg.settings.project.scopes != null);
        message = "programs.caido: `project.name` is required when `project.scopes` is set.";
      }
      {
        assertion = !(cfg.settings.networking.ca.path == null && cfg.settings.networking.ca.password != null);
        message = "programs.caido: `networking.ca.path` is required when `networking.ca.password` is set.";
      }
    ];

    warnings =
      lib.optional (cfg.settings.cloud.registration_key != null)
      "programs.caido: cloud.registration_key will be world-readable in the Nix store."
      ++ lib.optional (cfg.settings.networking.ca.password != null)
      "programs.caido: networking.ca.password will be world-readable in the Nix store.";

    home.packages =
      [cfg.package]
      ++ lib.optional cfg.installWrapper (pkgs.writeShellScriptBin "caido-managed" ''
        exec ${lib.getExe' cfg.package "caido-cli"} --config "${config.xdg.configHome}/${cfg.configPath}" "$@"
      '');

    xdg.configFile.${cfg.configPath}.source = configFile;
  };
}
