defmodule ChatServer do
  require Logger
  require Amnesia
  require Amnesia.Helper
  require Database.User
  
  alias :mnesia, as: Mnesia
  
  alias Database.User

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(ChatServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    case read_line(socket) do
        {:ok, data} ->
          case ChatServer.Command.parse(data) do
            {:ok, {:connect, user}} -> connect(socket, user)
            {:ok, {:disconnect, _}} -> disconnect(socket)
            {:ok, {:broadcast, message}} -> broadcast(message)
            {:ok, {:register, user, password}} -> register(socket, user, password)
            {:ok, {:auth, user, password}} -> auth(socket, user, password)
            {:error, :unknown} -> write_line(socket, {:error, :unknown_command})
          end
      end
  
    serve(socket)
  end
  
  defp connect(socket, nickname) do

    pid = Process.whereis(ChatWorker)
    :ok = GenServer.call(pid, {:connect, socket, nickname})
    
    write_line(socket, {:ok, "Connected #{nickname}\r\n"})
  end
  
  defp disconnect(socket) do
    pid = Process.whereis(ChatWorker)
    :ok = Genserver.call(pid, {:disconnect, socket})
    
    write_line(socket, :disconnect)
  end
  
  defp broadcast(message) do
    pid = Process.whereis(ChatWorker)
    GenServer.cast(pid, {:broadcast, message})
  end
  
  defp register(socket, name, password) do
    name = String.downcase(name)
    res = Mnesia.transaction(
      fn -> 
        Mnesia.match_object({Database.User, name, :_, :_})
      end
    )
    
    {:atomic, users} = res
    if length(users) == 0 do
      Mnesia.transaction(
        fn ->
          Mnesia.write({User, name, password, false})
        end
      )
      write_io_data(socket, {:ok, welcome_message(name)})
    else
      write_line(socket, {:error, "User #{name} is already registered!"})
    end
  end
  
  defp auth(socket , name, pass) do
    name = String.downcase(name)
    res = Mnesia.transaction(
      fn -> 
        Mnesia.match_object({Database.User, name, :_, :_})
      end
    )
    {:atomic, data} = res
    if length(data) == 0 do
      write_line(socket, {:error, "User #{name} is not registered!"})
    else
      user_data = Enum.at(data,0)
      {_, name, password, auth} = user_data
      if auth do
        write_line(socket, {:error, "User #{name} is already authorised!"})
      else
        if password != pass do
          write_line(socket, {:error, "Wrong Password"})
        else
          Mnesia.transaction(
            fn ->
              Mnesia.write({User, name, password, true})
            end
          )
          write_line(socket, {:ok, "User #{name} authorsied successfully!!"})
        end
      end
    end
  end
  
  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end
  
  defp write_io_data(socket, {:ok, io_list}) do
    :gen_tcp.send(socket, io_list)
  end
  
  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, "#{text}\r\n")
  end
  
  defp write_line(socket, {:error, :unknown_command}) do
    # Known error; write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end
  
  defp write_line(socket, :disconnect) do
    :gen_tcp.send(socket, "Disconnected!!")
    # The connection was closed, exit politely
    exit(:shutdown)
  end
  
  defp write_line(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "#{error}\r\n")
  end
  
  def welcome_message(name) do
    ["Welcome ", name, ". You are registered. Please authorize ", name, " by calling auth with correct password. Have a good day ", name, "\r\n"]
  end
  
  
end
