defmodule Last10kWeb.FilingsLive do
  use Phoenix.LiveView

  alias Last10k.Filing
  alias Last10k.LatestFilings

  def render(assigns) do
    ~H"""
      <table>
        <thead>
          <th>Company</th>
          <th>Accepted</th>
        </thead>
        <tbody id="filings" phx-update="stream">
          <tr
            :for={{id, filing} <- @streams.filings}
            id={id}
          >
            <td><%= filing.company %></td>
            <td>
              <%= display_date(filing.acceptanceDate) %><br />
              <small><%= display_time(filing.acceptanceDate) %> EST</small>
            </td>
          </tr>
        </tbody>
      </table>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)

    {:ok, stream(socket, :filings, [])}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)

    url = Application.get_env(:last10k, Last10kWeb.Endpoint)[:liveview_feed_url]
    headers = ["user-agent": Application.get_env(:last10k, Last10kWeb.Endpoint)[:liveview_feed_agent]]

    filings =
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

    {:noreply, stream(socket, :filings, filings.filings)}
  end

  defp parse(feed) do
    parsed_feed =
      case FastRSS.parse_atom(feed) do
        {:ok, map_of_feed} ->
          entries = Map.get(map_of_feed, "entries")
          %LatestFilings{
            count: length(entries),
            filings: entries |> Stream.map(&get_entry(&1))
          }
        {:error, "parse error"} ->
          IO.puts("parse error")
      end

    {:ok, parsed_feed}
  end

  defp get_entry(entry) do
    title = entry["title"]["value"]
    updated = NaiveDateTime.from_iso8601(entry["updated"])
    categories = entry["categories"]
    category = List.first(categories)["term"]
    links = entry["links"]
    link = List.first(links)["href"]
    uri = URI.parse(link)
    uri_path_parts = Path.split(uri.path)
    cik = Enum.at(uri_path_parts, 4)
    index_file = Enum.at(uri_path_parts, 6)
    accessionNumber = String.replace(index_file, "-index.htm", "")

    %Filing{
      id: title,
      cik: cik,
      accessionNumber: accessionNumber,
      company: title,
      formType: category,
      acceptanceDate: updated |> elem(1),
      url: uri
    }

  end

  defp display_date(value) do
    Enum.join [value.year, value.month, value.day], "-"
  end

  defp display_time(value) do
    Enum.join [value.hour, value.minute, value.second], ":"
  end

end
