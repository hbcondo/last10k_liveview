defmodule Last10kWeb.ErrorJSONTest do
  use Last10kWeb.ConnCase, async: true

  test "renders 404" do
    assert Last10kWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Last10kWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
