defmodule Credo.Check.Warning.RaiseInsideRescue do
  @moduledoc """
  Using `Kernel.raise` inside of a `rescue` block creates a new stacktrace,
  which obscures the cause of the original error.

  Example:

      # Prefer

      try do
        raise "oops"
      rescue
        e ->
          stacktrace = System.stacktrace # get the stacktrace of the exception
          Logger.warn("An exception has occurred")
          reraise e, stacktrace
      end

      # to

      try do
        raise "oops"
      rescue
        e ->
          Logger.warn("An exception has occurred")
          raise e
      end
  """

  @explanation [check: @moduledoc]

  use Credo.Check
  alias Credo.Code.Block

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:try, _meta, _arguments} = ast, issues, issue_meta) do
    case Block.rescue_block_for(ast) do
      {:ok, branches} ->
        {_, issues_found} =
          branches
          |> Enum.map(&extract_block/1)
          |> Enum.reject(&is_nil/1)
          |> Macro.prewalk([], &find_issues(&1, &2, issue_meta))
        {ast, issues ++ issues_found}
      :otherwise ->
        {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp extract_block({:->, _m, [_binding, expression]}), do: expression
  defp extract_block(_), do: nil

  defp find_issues({:raise, meta, _arguments} = ast, issues, issue_meta) do
    line = meta[:line]
    issue = issue_for(issue_meta, line)

    {ast, issues ++ [issue]}
  end
  defp find_issues(ast, issues, _), do: {ast, issues}

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Use reraise inside a rescue block to preserve the original stacktrace.",
      trigger: "raise",
      line_no: line_no
  end
end
