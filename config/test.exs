use Mix.Config

config :janitor, env: :test
config :logger, level: :warn

config :janitor,
  bucket_store: Janitor.Boundary.TestBucket
