import Config

config :norm, 
  enable_contracts: Mix.env == :test

import_config "#{config_env()}.exs"
