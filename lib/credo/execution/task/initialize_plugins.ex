defmodule Credo.Execution.Task.InitializePlugins do
  @moduledoc false

  alias Credo.Execution

  def call(exec, _opts) do
    Enum.reduce(exec.plugins, exec, &init_plugin(&2, &1))
  end

  defp init_plugin(exec, {_mod, false}), do: exec

  defp init_plugin(exec, {mod, _params}) do
    exec = Execution.set_initializing_plugin(exec, mod)

    case mod.init(exec) do
      %Execution{} = exec ->
        Execution.set_initializing_plugin(exec, nil)

      value ->
        raise "Expected #{mod}.init/1 to return %Credo.Execution{}, got: #{inspect(value)}"
    end
  end
end
