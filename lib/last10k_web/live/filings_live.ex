defmodule Last10kWeb.FilingsLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    Render Filings...<%= @myvalue %>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)

    myvalue = 0
    {:ok, assign(socket, myvalue: myvalue)}
  end

  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 1000)
    myvalue = :rand.uniform(100)
    {:noreply, assign(socket, :myvalue, myvalue)}
  end

end
