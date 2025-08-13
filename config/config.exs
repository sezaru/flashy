import Config

config :esbuild,
  version: "0.25.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2022 --format=cjs --minify --outfile=../priv/static/flashy.min.js --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.0.9",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]
