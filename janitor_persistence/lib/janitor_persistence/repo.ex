defmodule JanitorPersistence.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :janitor_persistence, adapter: Ecto.Adapters.SQLite3

  # def init(_, config) do
  #   config = Confex.Resolver.resolve!(config)

  #   unless config[:database] do
  #     raise "Set the required database environment variables!"
  #   end

  #   {:ok, config}
  # end
end
