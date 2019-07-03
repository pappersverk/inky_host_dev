defmodule InkyHostDev.HAL do
  @behaviour Inky.HAL

  defmodule State do
    @moduledoc false

    @state_fields [:canvas_pid, :display]

    @enforce_keys @state_fields
    defstruct @state_fields
  end

  @impl Inky.HAL
  def init(args) do
    display = Map.fetch!(args, :display)
    canvas_config = %{size: {display.width, display.height}, accent: display.accent}
    {:wx_ref, _, :wxFrame, pid} = InkyHostDev.Canvas.start_link(canvas_config)
    %State{canvas_pid: pid, display: display}
  end

  @impl Inky.HAL
  def handle_update(pixels, border, _push_policy, _state = %State{canvas_pid: canvas_pid}) do
    GenServer.call(canvas_pid, {:draw_pixels, pixels, border})
    :ok
  end
end
