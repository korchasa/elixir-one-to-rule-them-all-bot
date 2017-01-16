require IEx

defmodule OneToRuleThemAllBot.CLI do

  import Nadia.API

  def main([executors_path]) do
    executors_dir = Path.absname(executors_path)
    IO.puts "Executors dir:\t#{executors_dir}"
    HTTPoison.start
    get_all_executors(executors_dir)
    |> process(nil)
  end

  defp process(executors, prev_update) do
    {_, updates} = get_updates_after(prev_update)
    IO.puts "Updates:\t" <> Integer.to_string(length(updates))
    for update <- updates,
        executor <- executors,
        response <- send_to_executors(update, executor) do
      send_to_telegram(response, update)
    end
    :timer.sleep(1000)
    process(executors, List.last(updates))
  end

  def send_to_telegram(response, update) do
    default_params =
      case response["method"] do
        "sendMessage" -> %{"chat_id" => update.message.chat.id}
        _             -> %{}
      end
    request(response["method"], Map.merge(response["params"], default_params))
  end

  defp get_all_executors(dir) do
    executors = File.ls!(dir)
    IO.puts "Executors:\t" <> Enum.join(executors, ", ")
    Enum.map(executors, fn(executor) -> "#{dir}/#{executor}" end)
  end

  defp get_updates_after(prev_update) do
    case prev_update do
      nil    -> Nadia.get_updates
      update -> Nadia.get_updates offset: update.update_id + 1
    end
  end

  def send_to_executors(update, executor) do
    update_json = Poison.encode!(update)
    IO.puts "Executed:\t#{executor}\"\nInput:\t\t" <> String.replace(update_json, "\n", "\t\t\n")
    {output, status} = System.cmd executor, [update_json], stderr_to_stdout: true
    IO.puts "Output (#{status}):\t#" <> String.replace(output, "\n", "\n\t\t")
    case {output, status} do
      {"", 0} -> []
      {output, 0} -> Poison.decode!(output)
      _ -> []
    end
  end
end
