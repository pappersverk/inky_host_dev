defmodule InkyHostDev.Canvas do
  @behaviour :wx_object

  alias Inky.PixelUtil

  @title "Inky"

  @color_map_black %{black: 0, miss: 1}
  @color_map_accent %{red: 1, yellow: 1, accent: 1, miss: 0}

  def start_link(config) do
    :wx_object.start_link(__MODULE__, config, [])
  end

  def init(%{size: size, accent: accent}) do
    IO.puts("new..")
    wx = :wx.new()
    frame = :wxFrame.new(wx, -1, @title, size: size)
    :wxWindow.setClientSize(frame, size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame, size: size)
    :wxPanel.connect(panel, :paint, [:callback])
    :wxFrame.show(frame)

    state = %{
      panel: panel,
      size: size,
      frame: frame,
      accent: accent,
      black_bits: nil,
      accent_bits: nil
    }

    Process.send_after(self(), :refresh, 200)
    {frame, state}
  end

  @spec handle_call({:draw_pixels, any}, any, %{pixels: any}) :: {:reply, nil, %{pixels: any}}
  def handle_call({:draw_pixels, pixels}, from, state = %{size: size}) do
    {width, height} = size
    black_bits = PixelUtil.pixels_to_bits(pixels, width, height, 0, @color_map_black)
    accent_bits = PixelUtil.pixels_to_bits(pixels, width, height, 0, @color_map_accent)
    handle_call({:draw_pixels, black_bits, accent_bits}, from, state)
  end

  def handle_call({:draw_pixels, black_bits, accent_bits}, _from, state) do
    state = %{state | black_bits: black_bits, accent_bits: accent_bits}
    {:reply, nil, state}
  end

  def handle_info(:refresh, state) do
    :wxWindow.refresh(state.frame)
    Process.send_after(self(), :refresh, 2000)
    {:noreply, state}
  end

  defp draw_pixel(_, _, _, _, nil) do
  end

  # defp draw_pixel(dc, x, y, brushes, color) do
  #   brush = brushes[color]

  #   :wxDC.setBrush(dc, brush)
  #   :wxDC.setPen(dc, :wxPen.new({255, 255, 255, 0}))
  #   :wxDC.drawRectangle(dc, {x, y}, {x + 1, y + 1})
  # end

  defp draw_pixel(_, _, _, _, 0) do

  end

  defp draw_pixel(dc, width, height, i, 1) do
    x = rem(i, width)
    y = floor(i/height)-1
    IO.puts("#{x},#{y}")
    :wxDC.drawRectangle(dc, {x, y}, {x + 1, y + 1})
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, _size, _}}, state) do
    {:noreply, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end

  def handle_sync_event({:wx, _, _, _, {:wxPaint, :paint}}, _, state) do
    %{
      panel: panel,
      frame: frame,
      accent: accent,
      black_bits: black_bits,
      accent_bits: accent_bits,
      size: {width, height}
    } = state

    # Must be created, even if not used.
    dc = :wxPaintDC.new(panel)

    accent_brush_color =
    case accent do
      :red -> {255, 0, 0}
      :yellow -> {255, 255, 0}
      _ -> {0, 255, 0}
    end

    brushes = %{
      black: :wxBrush.new({0, 0, 0}),
      white: :wxBrush.new({255, 255, 255}),
      accent: :wxBrush.new(accent_brush_color)
    }

    :wxDC.setBrush(dc, brushes.white)
    :wxDC.clear(dc)

    # IO.inspect(black_bits)
    # IO.inspect(accent_bits)

    :wxDC.setPen(dc, :wxPen.new({255, 255, 255, 0}))
    :wxDC.setBrush(dc, brushes.black)
    Enum.map(
      Enum.with_index(
        for <<b::1 <- black_bits>>, do: b
      ), fn {b, index} ->
      # The black is inverted
      b = case b do
        1 -> 0
        0 -> 1
      end
      draw_pixel(dc, width, height, index, b)
      nil
    end)

    # :wxDC.setBrush(dc, brushes.accent)
    # Enum.map(Enum.with_index(for <<b::1 <- accent_bits>>, do: b), fn {b, index} ->
    #   draw_pixel(dc, width, height, index, b)
    # end)

    # for y <- 0..(height - 1),
    #     x <- 0..(width - 1),
    #     do: draw_pixel(dc, x, y, brushes, pixels[{x, y}])

    :wxWindow.show(frame)
    :wxPaintDC.destroy(dc)

    :ok
  end
end
