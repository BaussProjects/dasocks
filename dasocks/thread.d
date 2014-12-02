/*
	Provides a simple thread management module.
	
	Author: Bauss
*/
module dasocks.thread;

import core.thread;

import dasocks.events;

/**
*	The thread start events.
*/
private shared ThreadStartEvent[] threadStartEvents;

/**
*	Adds an event to the thread start events.
*	These type of events are useful for copying shared data into a non-shared thread-local space.
*/
void addEvent(ThreadStartEvent event) {
	synchronized {
		auto tse = cast(ThreadStartEvent[])threadStartEvents;
		tse ~= event;
		threadStartEvents = cast(shared(ThreadStartEvent[]))tse;
	}
}

/**
*	Creates a new thread using a function pointer.
*/
Thread createThread(void function() F) {
	Thread t;
	t = new Thread({
		synchronized {
			auto current = Thread.getThis();
		
			if (threadStartEvents) {
				auto tse = cast(ThreadStartEvent[])threadStartEvents;
				foreach (event; tse)
					event.exec(t,current);
			}
		}
		
		F();
	});
	return t;
}

/**
*	Creates a new thread using a delegate.
*/
Thread createThread(void delegate() D) {
	Thread t;
	t = new Thread({
		synchronized {
			auto current = Thread.getThis();
		
			if (threadStartEvents) {
				auto tse = cast(ThreadStartEvent[])threadStartEvents;
				foreach (event; tse)
					event.exec(t,current);
			}
		}
		
		D();
	});
	return t;
}

/**
*	Sleeps the current thread for a specific amount of milliseconds.
*/
void sleep(size_t milliseconds) {
	Thread.sleep(dur!("msecs")(milliseconds));
}