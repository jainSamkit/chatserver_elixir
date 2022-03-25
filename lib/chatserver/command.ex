defmodule ChatServer.Command do
  
  def parse(line) do
    case String.split(line) do
      ["CONNECT", user] -> {:ok, {:connect, user}}
      ["DISCONNECT", user] -> {:ok, {:disconnect, user}}
      ["SEND",message] -> {:ok, {:broadcast, message}}
      ["REGISTER", user, password] -> {:ok, {:register, user, password}}
      ["AUTH", user, password] -> {:ok, {:auth, user, password}}
      _ -> {:error, :unknown}
    end
  end
  
  def run(command, socket) do
    {:ok, "OK\r\n"}
    case command do
      {:connect, _} -> IO.inspect(socket)
      {:disconnect, _} -> IO.inspect(socket)
      {:send, _} -> IO.inspect(socket)
    end
  end
end
