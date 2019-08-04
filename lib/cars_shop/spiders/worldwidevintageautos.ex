defmodule CarsShop.Worldwidevintageautos do
  @behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.worldwidevintageautos.com"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.worldwidevintageautos.com/inventory/",
        "https://www.worldwidevintageautos.com/browse-by-make/"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    pagination_urls =
      response.body |> Floki.find("a.paginate") |> Floki.attribute("href")

    product_urls =
      response.body |> Floki.find("a.item-title") |> Floki.attribute("href")

    by_make_urls =
      response.body |> Floki.find(".browse-makes a") |> Floki.attribute("href")

    requests =
      (product_urls ++ pagination_urls ++ by_make_urls)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    vehicle_data =
      response.body
      |> Floki.find("script")
      |> Enum.map(fn item -> Floki.DeepText.get(item) end)
      |> Enum.filter(fn item -> String.contains?(item, "vehicleData") end)
      |> Floki.text()
      |> String.replace("'", "")

    make_data =
      Regex.named_captures(~r/make: (?<make>[^,]+)/, vehicle_data) || %{}

    year_data =
      Regex.named_captures(~r/year: (?<year>[^,]+)/, vehicle_data) || %{}

    item = %{
      id:
        response.body
        |> Floki.find("#vehicle_stock")
        |> Floki.attribute("value")
        |> Floki.text(),
      name: response.body |> Floki.find("h1.vehicle-title") |> Floki.text(),
      price: response.body |> Floki.find(".price-amount") |> Floki.text(),
      make: Map.get(make_data, "make"),
      year: Map.get(year_data, "year"),
      description:
        response.body |> Floki.find(".vehicle-description") |> Floki.text(),
      images:
        response.body |> Floki.find("ul#thumbs img") |> Floki.attribute("src"),
      url: response.request_url
    }

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
