defmodule InkyHostDev.Canvas do
  @behaviour :wx_object

  @title "Inky"

  def start_link(config) do
    :wx_object.start_link(__MODULE__, config, [])
  end

  def init(%{size: base_size, accent: accent}) do
    {width, height} = base_size

    wx = :wx.new()
    # Allow room for a border
    size = {width + 2, height + 2}
    frame = :wxFrame.new(wx, -1, @title, size: size)
    :wxWindow.setClientSize(frame, size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame, size: size)
    :wxPanel.connect(panel, :paint, [:callback])
    :wxFrame.show(frame)

    state = %{
      wx: wx,
      panel: panel,
      size: base_size,
      frame: frame,
      accent: accent,
      pixels: %{},
      border: nil
    }

    Process.send_after(self(), :refresh, 200)
    {frame, state}
  end

  def handle_call({:draw_pixels, pixels, border}, _from, state) do
    state = %{state | pixels: pixels, border: border}
    {:reply, nil, state}
  end

  def handle_info(:refresh, state) do
    :wxWindow.refresh(state.frame)
    {:noreply, state}
  end

  defp draw_pixel(_, _, _, _, nil) do
  end

  defp draw_pixel(dc, x, y, brushes, color) do
    brush = brushes[color]

    if brush != nil do
      :wxDC.setBrush(dc, brush)
      :wxDC.drawRectangle(dc, {x, y}, {x + 1, y + 1})
    end
  end

  defp draw_border(dc, width, height, brushes, border) do
    for y <- [1, height + 1],
        x <- 1..(width + 1),
        do: draw_pixel(dc, x, y, brushes, border)

    for x <- [1, width + 1],
        y <- 1..(height + 1),
        do: draw_pixel(dc, x, y, brushes, border)
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, _size, _}}, state) do
    {:noreply, state}
  end

  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    :wxPanel.destroy(state.panel)
    :wxFrame.destroy(state.frame)
    :wx.destroy()
    {:stop, :normal, state}
  end

  def handle_sync_event({:wx, _, _, _, {:wxPaint, :paint}}, _, state) do
    %{
      panel: panel,
      frame: frame,
      accent: accent,
      pixels: pixels,
      border: border
    } = state

    # Must be created, even if not used.
    dc = :wxPaintDC.new(panel)

    accent_brush_color =
      case accent do
        :red -> {200, 0, 0}
        :yellow -> {200, 200, 0}
        _ -> {0, 255, 0}
      end

    accent_brush = :wxBrush.new(accent_brush_color)

    brushes = %{
      black: :wxBrush.new({0, 0, 0}),
      white: :wxBrush.new({255, 255, 255}),
      accent: accent_brush,
      red: accent_brush,
      yellow: accent_brush
    }

    {width, height} = state.size

    :wxDC.setPen(dc, :wxPen.new({255, 255, 255, 0}))

    for y <- 1..height,
        x <- 1..width,
        do: draw_pixel(dc, x + 1, y + 1, brushes, pixels[{x, y}])

    draw_border(dc, width, height, brushes, border)

    :wxWindow.show(frame)

    :wxPaintDC.destroy(dc)
    :wxBrush.destroy(brushes.accent)

    Process.send_after(self(), :refresh, 200)
    :ok
  end
end
