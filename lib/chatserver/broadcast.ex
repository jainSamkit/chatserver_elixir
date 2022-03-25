defmodule ChatServer.Broadcast do
  use GenServer, restart: :permanent
  
  def init(_init_arg) do
    {:ok, %{}}
  end
  
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: ChatServer.Broadcast)
  end
  
  def handle_cast({:send, text}, state) do
    sockets = Map.keys(state)
    Enum.each(sockets, fn socket -> 
      :gen_tcp.send(socket, text <> "\r\n")
    end)
    
    {:noreply, state}
  end
  
  
  def handle_call({:connect, socket, nickname}, _from, state) do
    state = Map.put(state, socket, nickname)
    {:reply, :ok ,state}
  end
  
  def handle_call({:disconnect,socket} ,_from, state) do
    state = Map.delete(state, socket)
    {:reply, :ok, state}
  end
end