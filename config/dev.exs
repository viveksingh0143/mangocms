import Config

config :mangocms, MangoCMS.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :mangocms, MangoCMSWeb.Endpoint,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:mangocms, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:mangocms, ~w(--watch)]}
  ],
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
      ~r"priv/gettext/.*\.po$"E,
      ~r"lib/mangocms_web/router\.ex$"E,
      ~r"lib/mangocms_web/(controllers|live|components)/.*\.(ex|heex)$"E
    ]
  ]

config :mangocms, dev_routes: true
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :swoosh, :api_client, false

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
