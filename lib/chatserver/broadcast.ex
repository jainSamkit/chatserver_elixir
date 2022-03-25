defmodule ChatServer.Broadcast do
  use GenServer, restart: :permanent
  
  def init(state) do
    IO.inspect(state, label: "broadcst_state")
    {:ok, state}
  end
  
  def start_link(state) do
    IO.inspect(state, label: "state_start_link")
    GenServer.start_link(__MODULE__, state, name: ChatServer.Broadcast)
  end
  
  
  
end