defmodule Last10kWeb.FilingsLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    Render Filings...
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end
