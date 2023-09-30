defmodule Last10kWeb.FilingsLive do
  @filings_timezone "America/New_York"
  use Phoenix.LiveView

  alias Phoenix.LiveView.JS
  alias Last10k.Filing
  alias Last10k.LatestFilings
  alias Timex

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)

    mount_filings = get_filings().filings

    {:ok, stream(socket, :filings, mount_filings)}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)

    new_filings = get_filings().filings

    {:noreply, stream(socket, :filings, new_filings, at: 0)}
  end

  defp get_filings() do
    url = Application.get_env(:last10k, Last10kWeb.Endpoint)[:liveview_feed_url]
    headers = ["user-agent": Application.get_env(:last10k, Last10kWeb.Endpoint)[:liveview_feed_agent]]

    _filings =
      case HTTPoison.get(url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          #IO.puts body
          {:ok, feed} = parse(body)
          _feed = feed
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts "Not found :("
        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect reason
      end
  end

  defp parse(feed) do
    parsed_feed =
      case FastRSS.parse_atom(feed) do
        {:ok, map_of_feed} ->
          entries = Map.get(map_of_feed, "entries")

          filings_map = entries |> Stream.map(&get_entry(&1))
          filings_list = Enum.to_list(filings_map)
          filings_list |> Enum.sort(&(DateTime.after?(&1.acceptanceDate, &2.acceptanceDate)))
          filings_list |> Enum.sort_by(&{&1.cik}, :desc)

          %LatestFilings{
            count: length(filings_list),
            lastUpdated: List.first(filings_list).acceptanceDate,
            filings: Enum.uniq(filings_list)
          }
        {:error, "parse error"} ->
          IO.puts("parse error")
      end
    {:ok, parsed_feed}
  end

  defp get_entry(entry) do
    title = entry["title"]["value"]
    updated = NaiveDateTime.from_iso8601(entry["updated"]) |> elem(1)
    categories = entry["categories"]
    category = List.first(categories)["term"]
    links = entry["links"]
    link = List.first(links)["href"]
    uri = URI.parse(link)
    uri_path_parts = Path.split(uri.path)
    cik = Enum.at(uri_path_parts, 4)
    index_file = Enum.at(uri_path_parts, 6)
    accessionNumber = String.replace(index_file, "-index.htm", "")
    summary = entry["summary"]["value"]

    %Filing{
      id: "#{cik}.#{accessionNumber}",
      cik: Integer.parse(cik),
      accessionNumber: accessionNumber,
      company: get_filer(title),
      reportingType: get_reporting_type(title),
      formType: category,
      acceptanceDate: Timex.to_datetime(updated, @filings_timezone),
      url_html: uri,
      url_text: String.replace(link, "-index.htm", ".txt"),
      filingDate: get_filed(summary),
      items: get_items(summary, category)
    }
  end

  defp get_filer(title) do
    matches = Regex.run(~r/(?<=\-\s)(.*?)(?=\s\()/, title)
    List.first(matches)
  end

  defp get_reporting_type(title) do
    matches = Regex.scan(~r/(?<=\()(.*?)(?=\))/, title, capture: :all_but_first)
    List.last(matches, "")
  end

  defp get_filed(summary) do
    filed_string = String.slice(summary, 16, 10)
    filed_result = Date.from_iso8601(filed_string)
    filed_result |> elem(1)
  end

  defp get_items(summary, formType) do
      if formType == "8-K" or formType == "8-K/A" do
        items = String.split(summary, "<br>")
        Enum.drop(items, 1)
      else
        []
      end
  end

  defp display_date(value) do
    Enum.join [value.year, value.month, value.day], "-"
  end

  defp display_time(value) do
    Enum.join [value.hour, value.minute, value.second], ":"
  end

end
