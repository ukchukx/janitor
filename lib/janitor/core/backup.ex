defmodule Janitor.Core.Backup do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:id, :name, :download_link]

  @type t() :: %__MODULE__{
          id: binary,
          download_link: map,
          name: binary
        }
end
