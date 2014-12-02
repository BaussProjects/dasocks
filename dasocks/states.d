/*
	Provides a state manager.
*/
module dasocks.states;

import dasocks.events;

/**
*	An asynchronous receive state wrapper.
*/
class AsyncSocketReceiveState {
	/**
	*	The expected size of the packet.
	*/
	size_t expected;
	/**
	*	The amount of bytes still to be received.
	*/
	size_t returning;
	/**
	*	The buffer of the packet.
	*/
	ubyte[] buffer;
	/**
	*	The event to be executed when received.
	*/
	AsyncSocketEvent finished;
	
	/**
	*	Creates a new instance of AsyncSocketReceiveState.
	*/
	this(size_t size, AsyncSocketEvent onfinished) {
		expected = size;
		returning = expected;
		finished = onfinished;
	}
	
	/**
	*	Returns true if the packet has been received.
	*/
	@property bool ready() {
		if (!buffer)
			return false;
		return (buffer.length == expected);
	}
}