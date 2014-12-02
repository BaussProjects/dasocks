/*
	Provides a manager for asynchronous threads.
	
	Author: Bauss
*/
module dasocks.asyncthread;

import core.thread;
import std.socket;

import dasocks.thread;
import dasocks.asynctcpsocket;

/**
*	The asynchronous socket threads.
*/
private shared AsyncThread[] threads;

/**
*	Adds an asynchronous tcp socket to an available thread.
*/
void addAsyncSocket(AsyncTcpSocket socket) {
	synchronized {
		auto t = cast(AsyncThread[])threads;
		foreach (art; t) {
			if (art.add(socket))
				return;
		}
		auto art = new AsyncThread;
		art.add(socket);
		t ~= art;
		threads = cast(shared(AsyncThread[]))t;
	}
}

/**
*	Removes an asynchronous tcp socket from its thread.
*/
void removeAsyncSocket(AsyncTcpSocket socket) {
	synchronized {
		auto t = cast(AsyncThread[])threads;
		foreach (art; t) {
			art.remove(socket);
		}
	}
}

/**
*	A wrapper around an asynchronous socket thread handling accept() and receive() asynchronously.
*/
private class AsyncThread {
	/**
	*	The thread.
	*/
	Thread m_thread;
	/**
	*	The sockets.
	*/
	AsyncTcpSocket[size_t] m_sockets;

	/**
	*	Creates a new instance of AsyncThread.
	*/
	this() {
		m_thread = createThread(&handle);
		m_thread.start();
	}
	
	/**
	*	Attempts to add a tcp socket to the thread.
	*	Returns false if the thread is not available.
	*/
	bool add(AsyncTcpSocket socket) {
		synchronized {
			if (!m_sockets || m_sockets.length < size_t.sizeof) {
				m_sockets[socket.socketId] = socket;
				return true;
			}
		}
		return false;
	}
	
	/**
	*	Removes a tcp socket from the thread.
	*/
	void remove(AsyncTcpSocket socket) {
		synchronized {
			if (!m_sockets)
				return;
			if (m_sockets.length == 0)
				return;
			if (m_sockets.get(socket.socketId, null) !is null)
				m_sockets.remove(socket.socketId);
		}
	}
	
	/**
	*	Handling the event poll of the sockets.
	*/
	void handle() {
		while (true) {
			synchronized {
				if (!m_sockets) {
					sleep(1);
					continue;
				}
			}
			
			auto selectSet = new SocketSet;
			int selectResult;
			
			synchronized {
				foreach (s; m_sockets) {
					selectSet.add(s.socket);
				}
				
				selectResult = Socket.select(selectSet, null, null);
			}
			
			if (selectResult < 1)
				continue;
			
			size_t[] socketKeys;
			synchronized {
				socketKeys = m_sockets.keys;
			}
			
			foreach (key; socketKeys) {
				handleSocket(selectSet, key);
			}
		}
	}
	
	/**
	*	Handling each socket that's handled by the select.
	*/
	void handleSocket(SocketSet selectSet, int key) {
		synchronized {
			auto socket = m_sockets[key];
			if (!selectSet.isSet(socket.socket))
				return;
				
			if (socket.listening) {
				// New connection ...
				if (socket.onAccept)
					socket.onAccept.exec(socket);
			}
			else {
				auto state = socket.receiveState;
				if (!state)
					return;
				
				ubyte[] recvBuffer = new ubyte[state.returning];
				
				int recv = socket.socket.receive(recvBuffer);
				if (recv == 0 || recv == Socket.ERROR) {
					// Disconnected ...
					socket.close();
				}
				else {
					state.buffer ~= recvBuffer;
					if (state.ready) {
						// All bytes received
						state.finished.exec(socket);
					}
					else {
						// Still bytes to be received
						state.returning -= recv;
					}
				}
			}
		}
	}
}