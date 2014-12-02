/*
	Provides a simple UID generator.
	
	Author: Bauss
*/
module dasocks.uid;

/**
*	The next UID.
*/
private shared size_t nextUID;

/**
*	Gets the next UID.
*/
size_t getNextUID() {
	synchronized {
		size_t next = cast(size_t)nextUID;
		nextUID = cast(shared(size_t))(next + 1);
		return next;
	}
}