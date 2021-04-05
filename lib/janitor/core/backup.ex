defmodule Janitor.Core.Backup do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:id, :name, meta: %{}]

  @type t() :: %__MODULE__{
          id: binary,
          name: binary,
          meta: map
        }
end
