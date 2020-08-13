defmodule MKV.Ranch.Protocol do
  # based on:
  # - https://github.com/ninenines/ranch/blob/master/examples/tcp_echo/src/echo_protocol.erl
  # - https://github.com/ninenines/ranch/blob/master/examples/tcp_reverse/src/reverse_protocol.erl
  # - https://blog.oestrich.org/2017/07/using-ranch-with-elixir/
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def init(ref, socket, transport) do
    Logger.info "Starting #{__MODULE__}"
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, :once}])
    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
  end

  def handle_info({:tcp, socket, data}, state = %{socket: socket, transport: transport}) do
    transport.setopts(socket, [{:active, :once}])
    state = handle_data(data, state)
    {:noreply, state}
  end
  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    IO.puts "Closing"
    transport.close(socket)
    {:stop, :normal, state}
  end

  defp handle_data(data, state) do
    Logger.debug "handling data: #{data}"
    entry = MKV.Protocol.decode!(data)
    MKV.Store.put(entry)
    state
  end

end
