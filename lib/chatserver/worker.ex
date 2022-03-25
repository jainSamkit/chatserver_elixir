defmodule ChatServer.Worker do
  use GenServer
  
  def init(socket_map) do
    {:ok, socket_map}
  end
  
  def start_link(socket_map) do
    GenServer.start_link(__MODULE__, socket_map, name: ChatWorker)
  end
  
  
  def handle_call({:connect,socket, user}, _from, state) do
    IO.inspect(socket, label: "socket")
    state = Map.put(state, socket, user)
    {:reply, :ok, state}
  end
  
  
  def handle_call({:disconnect, socket} , _from, state) do
    state = Map.delete(state, socket)
    {:reply, :ok, state}
  end
  
  def handle_cast({:broadcast, msg}, state) do
    sockets = Map.keys(state)
    Enum.each(sockets, fn socket -> 
      :gen_tcp.send(socket, msg)
    end)
    {:noreply, state}
  end

end