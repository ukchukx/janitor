defmodule Janitor.Core.Backup do
  @moduledoc false
  @derive Jason.Encoder
  defstruct ~w[name download_link]a

  @type t() :: %__MODULE__{
          download_link: binary,
          name: binary
        }
end
