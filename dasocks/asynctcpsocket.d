/*
	Provides a module for an asynchronous tcp socket handler.
*/
module dasocks.asynctcpsocket;

import std.socket;

import dasocks.asyncthread;
import dasocks.uid;
import dasocks.states;
import dasocks.events;
import dasocks.error;

/**
*	An asynchronous tcp socket.
*/
class AsyncTcpSocket {
private:
	/**
	*	The underlying system socket.
	*/
	Socket m_socket;
	/**
	*	A boolean controlling whether the socket is a listening socket or not.
	*/
	bool m_listening;
	/**
	*	The id of the socket.
	*/
	size_t m_socketId;
	/**
	*	The receive state of the socket.
	*/
	AsyncSocketReceiveState m_receiveState;
	
	/**
	*	The event executed once a socket is accepted.
	*/
	AsyncSocketEvent m_acceptInvoke;
	/**
	*	The event executed once a packet is received.
	*/
	AsyncSocketEvent m_receiveInvoke;
	/**
	*	The event executed once a disconnection or socket close is invoked.
	*/
	AsyncSocketEvent m_disconnectInvoke;
	
	/**
	*	Creates a new instance of AsyncTcpSocket.
	*/
	this(Socket socket) {
		m_socketId = getNextUID();
		m_socket = socket;
		m_socket.blocking = false;
		addAsyncSocket(this);
	}
public:
	/**
	*	Creates a new instance of AsyncTcpSocket.
	*/
	this(AddressFamily family = AddressFamily.INET) {
		m_socketId = getNextUID();
		m_socket = new TcpSocket(family);
		m_socket.blocking = false;
		m_listening = true;
	}
	
	/**
	*	Enables TCP keep-alive with the specified parameters.
	*/
	void setKeepAlive(int time, int interval)
	{
		m_socket.setKeepAlive(time, interval);
	}
	
	/**
	*	Sets the events of the socket.
	*/
	void setEvents(AsyncSocketEvent onAccept, AsyncSocketEvent onReceive, AsyncSocketEvent onDisconnect) {
		m_acceptInvoke = onAccept;
		m_receiveInvoke = onReceive;
		m_disconnectInvoke = onDisconnect;
	}
	
	/**
	*	Begins to receive a packet.
	*/
	void beginReceive(size_t size) {
		if (m_listening)
			throw new AsyncException("This is a listening socket.");
		if (m_receiveState)
			throw new AsyncException("Cannot receive more than one packet per socket at a time.");
		if (!m_receiveInvoke)
			throw new AsyncException("There is no receive event.");

		m_receiveState = new AsyncSocketReceiveState(size, m_receiveInvoke);
	}
	
	/**
	*	Retrieves the packet received.
	*/
	ubyte[] endReceive() {
		if (m_listening)
			throw new AsyncException("This is a listening socket.");
		if (!m_receiveState)
			throw new AsyncException("Call beginReceive() first.");
		if (!m_receiveState.ready)
			throw new AsyncException("Receive hasn't finished.");
		auto buff = m_receiveState.buffer.dup;
		m_receiveState = null;
		return buff;
	}
	
	/**
	*	Creates a sync receive.
	*/
	ubyte[] waitReceive(size_t size) {
		ubyte[] buf = new ubyte[size];
		m_socket.blocking = true;
		m_socket.receive(buf);
		m_socket.blocking = false;
		return buf;
	}
	
	/**
	*	Begins the acceptance of a socket.
	*/
	void beginAccept() {
		if (!m_listening)
			throw new AsyncException("This is not a listening socket.");
		if (!m_acceptInvoke)
			throw new AsyncException("There is no accept event.");
		addAsyncSocket(this);
	}
	
	/**
	*	Retrieves the accepted socket.
	*/
	AsyncTcpSocket endAccept() {
		if (!m_listening)
			throw new AsyncException("This is not a listening socket.");
		auto sock = m_socket.accept();
		if (!sock)
			throw new AsyncException("Please call beginAccept() and wait for the accept event to be called.");
		removeAsyncSocket(this);
		auto s = new AsyncTcpSocket(sock);
		s.setEvents(null, m_receiveInvoke, m_disconnectInvoke);
		return s;
	}
	
	/**
	*	Binds the socket to an internet address.
	*/
	void bind(Address addr) {
		if (!m_listening)
			throw new AsyncException("This is not a listening socket.");
		m_socket.bind(addr);
	}
	
	/**
	*	Starts listening for connections on the socket.
	*/
	void listen(int backlog) {
		if (!m_listening)
			throw new AsyncException("This is not a listening socket.");
		m_socket.listen(backlog);
	}
	
	/**
	*	Closes/Disconnects the socket
	*/
	void close() {
		removeAsyncSocket(this);
		m_socket.shutdown(SocketShutdown.BOTH);
		m_socket.close();
		
		if (m_disconnectInvoke)
			m_disconnectInvoke.exec(this);
	}
	
	/**
	*	Sends a buffer.
	*/
	void send(void[] buffer) {
		if (m_listening)
			throw new AsyncException("This is a listening socket.");
		m_socket.send(buffer);
	}
	
	@property {
		/**
		*	Returns true if the socket is a listening socket.
		*/
		bool listening() {
			return m_listening;
		}
		
		/**
		*	Gets the underlying system socket.
		*/
		Socket socket() {
			return m_socket;
		}
		
		/**
		*	Gets the socket id.
		*/
		size_t socketId() {
			return m_socketId;
		}
		
		/**
		*	Gets the receive state of the socket.
		*/
		AsyncSocketReceiveState receiveState() {
			return m_receiveState;
		}
		
		/**
		*	Gets the event for accept handling.
		*/
		AsyncSocketEvent onAccept() {
			return m_acceptInvoke;
		}
		
		/**
		*	Gets the event for receive handling.
		*/
		AsyncSocketEvent onReceive() {
			return m_receiveInvoke;
		}
		
		/**
		*	Gets the event for disconnect handling.
		*/
		AsyncSocketEvent onDisconnect() {
			return m_disconnectInvoke;
		}
	}
}
