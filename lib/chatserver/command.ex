defmodule ChatServer.Command do
  
  def parse(line) do
    case String.split(line) do
      ["CONNECT", user] -> {:connect, user}
      ["DISCONNECT", user] -> {:disconnect, user}
      ["SEND",message] ->  {:broadcast, message}
      ["REGISTER", user, password] -> {:register, user, password}
      ["AUTH", user, password] -> {:auth, user, password}
      _ -> {:error, :unknown}
    end
  end
end
