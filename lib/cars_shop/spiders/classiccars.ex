defmodule CarsShop.Classiccars do
  @behaviour Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://classiccars.com"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://classiccars.com/listings/find"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    urls = response.body |> Floki.find("a.d-block") |> Floki.attribute("href")

    pagination_urls =
      response.body |> Floki.find(".pagination a") |> Floki.attribute("href")

    requests =
      (urls ++ pagination_urls)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    item_attrs = response.body |> Floki.find("#listing-content")

    item = %{
      id: item_attrs |> Floki.attribute("data-listing") |> List.first(),
      name: response.body |> Floki.find("h1") |> Floki.text(),
      price:
        item_attrs
        |> Floki.attribute("data-listing-formatted-price")
        |> List.first(),
      make: item_attrs |> Floki.attribute("data-listing-make") |> List.first(),
      year: item_attrs |> Floki.attribute("data-listing-year") |> List.first(),
      description:
        response.body |> Floki.find("div.vehicle-description") |> Floki.text(),
      images:
        response.body
        |> Floki.find(".swiper-slide img")
        |> Floki.attribute("src"),
      url: response.request_url
    }

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
