defmodule OneToRuleThemAllBot.CLI do

  def main([executors_path]) do
    executors_dir = Path.absname(executors_path)
    IO.puts "Search executors in \"#{executors_dir}\""
    HTTPoison.start
    executors = get_all_executors(executors_dir)
    for update <- get_all_updates(),
    executor <- executors,
    response_calls = try_process_update(update, "#{executors_dir}/#{executor}"),
    response_calls do
      for call <- response_calls do
        default_params =
          case call["method"] do
            "sendMessage" -> %{"chat_id": update["message"]["chat"]["id"]}
            _             -> %{}
          end
        call_telegram(call["method"], Map.merge(call["params"], default_params))
      end
    end
  end

  defp get_all_executors(dir) do
    executors = File.ls!(dir)
    IO.puts "Executors: " <> Enum.join(executors, ", ")
    executors
  end

  defp get_all_updates() do
    call_telegram("getUpdates", {})
  end

  def try_process_update(update, executor) do
    {:ok, update_json} = JSON.encode(update)
    IO.puts "Executed:\t#{executor} \"" <> String.replace(update_json, "\"", "\\\"") <> "\""
    {output, status} = System.cmd executor, [update_json], stderr_to_stdout: true
    IO.puts "Output (#{status}):\t#{output}\n"
    case {output, status} do
      {"", 0} -> false
      {output, 0} -> {:ok, resp} = JSON.decode(output); resp
      _ -> false
    end
  end

  defp call_telegram(method, params) do
    {:ok, json_str} = JSON.encode(params)
    token = System.get_env("OTRTAB_TELEGRAM_TOKEN")
    case HTTPoison.post "https://api.telegram.org/bot#{token}/#{method}", json_str, [{"Content-Type", "application/json"}] do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body} = JSON.decode(body)
        body["result"]
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts "404"
          {}
          {:error, %HTTPoison.Error{reason: reason}} ->
            IO.inspect reason
            {}
          end
        end
      end