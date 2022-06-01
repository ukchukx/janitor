defmodule Janitor.Core.Backup do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:name, :download_link]

  @type t() :: %__MODULE__{
          download_link: binary,
          name: binary
        }
end
