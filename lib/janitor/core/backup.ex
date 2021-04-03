defmodule Janitor.Core.Backup do
  @moduledoc false
  defstruct [:id, :name, meta: %{}]

  @type t :: %{
          id: binary,
          name: binary,
          meta: map
        }
end
