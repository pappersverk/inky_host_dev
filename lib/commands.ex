defmodule InkyHostDev.Commands do
  @behaviour Inky.Commands
  # alias Inky.Commands

  defmodule State do
    @moduledoc false

    @state_fields [:canvas_pid]

    @enforce_keys @state_fields
    defstruct @state_fields
  end

  @impl true
  @spec init(any, any) :: InkyHostDev.Commands.State.t()
  def init(_io_mod \\ nil, _io_args \\ nil) do
    %State{canvas_pid: nil}
  end

  @impl true
  @spec handle_update(any, any, any, any, InkyHostDev.Commands.State.t()) ::
          InkyHostDev.Commands.State.t()
  def handle_update(display, buf_black, buf_accent, push_policy, state = %State{canvas_pid: nil}) do
    {:wx_ref, _, :wxFrame, pid} = InkyHostDev.Canvas.start_link(%{size: {display.width, display.height}, accent: display.accent})
    handle_update(display, buf_black, buf_accent, push_policy, %State{state | canvas_pid: pid})
  end

  @impl true
  def handle_update(_display, buf_black, buf_accent, _push_policy, state = %State{canvas_pid: canvas_pid}) do
    GenServer.call(canvas_pid, {:draw_pixels, buf_black, buf_accent})
    :ok
  end
end
