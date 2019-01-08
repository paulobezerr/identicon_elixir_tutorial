defmodule Identicon do
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def hash_input(input) do
    hex = :binary.bin_to_list(:crypto.hash(:md5, input))

    %Identicon.Image{text: input, hex: hex}
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  def build_grid(%Identicon.Image{} = image) do
    image_grid =
      image.hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{image | grid: image_grid}
  end

  def mirror_row(row) do
    [a, b, c] = row
    [a, b, c, b, a]
  end

  def filter_odd_squares(%Identicon.Image{} = image) do
    image_grid =
      Enum.filter(image.grid, fn({code, _index}) ->
        rem(code, 2) == 0
      end)

    %Identicon.Image{image | grid: image_grid}
  end

  def build_pixel_map(%Identicon.Image{} = image) do
    pixel_map =
      Enum.map(image.grid, fn({_code, index}) ->
        square_row_count = 5
        square_size = 50

        top_x = rem(index, square_row_count) * 50
        top_y = div(index, square_row_count) * 50
        bottom_x = top_x + square_size
        bottom_y = top_y + square_size

        {{top_x, top_y}, {bottom_x, bottom_y}}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  def save_image(image, filename) do
    File.write("#{filename}.png", image)
  end
end
