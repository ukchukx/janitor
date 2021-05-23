defmodule JanitorPersistence.Model do
  @moduledoc false

  @callback to_map(arg :: struct) :: map
  @callback from_model(arg :: struct) :: map
end
