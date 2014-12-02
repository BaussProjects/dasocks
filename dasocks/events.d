/*
	Provides a simplified event handler.
	
	Author: Bauss
*/
module dasocks.events;

/**
*	The event handler used for thread start events.
*	Thread start events are fired whenever a thread is created and started using the createThread() function.
*
*	Parameters: Each event takes the parameter of the current thread and parent thread (The thread that created the thread.)
*/
class ThreadStartEvent {
import core.thread : Thread;

private:
	/**
	*	The function pointer.
	*/
	void function(Thread,Thread) F;
	/**
	*	The delegate.
	*/
	void delegate(Thread,Thread) D;
public:
	/**
	*	Creates a new instance of BaseEvent.
	*/
	this(void function(Thread,Thread) F) {
		this.F = F;
	}
	/**
	*	Creates a new instance of BaseEvent.
	*/
	this(void delegate(Thread,Thread) D) {
		this.D = D;
	}
	
	/**
	*	Executes the event.
	*/
	void exec(Thread t1, Thread t2) {
		if (F) F(t1,t2);
		else if (D) D(t1,t2);
	}
}

/**
*	The event handler used for asynchronous events.
*	The events are fired each time a specific handling has been completed.
*
*	Parameters:
*	Each event takes a parameter for the handled socket.
*/
class AsyncSocketEvent {
import dasocks.asynctcpsocket;
private:
	/**
	*	The function pointer.
	*/
	void function(AsyncTcpSocket) F;
	/**
	*	The delegate.
	*/
	void delegate(AsyncTcpSocket) D;
public:
	/**
	*	Creates a new instance of BaseEvent.
	*/
	this(void function(AsyncTcpSocket) F) {
		this.F = F;
	}
	/**
	*	Creates a new instance of BaseEvent.
	*/
	this(void delegate(AsyncTcpSocket) D) {
		this.D = D;
	}
	
	/**
	*	Executes the event.
	*/
	void exec(AsyncTcpSocket s) {
		if (F) F(s);
		else if (D) D(s);
	}
}