/*
	Provides a module based on error handling.
	
	Author: Bauss
*/
module dasocks.error;

/**
*	An exception throwing during asynchronous handling.
*/
class AsyncException : Throwable {
public:
	/**
	*	Creates a new instance of AsyncException.
	*/
	this(string msg) {
		super(msg);
	}
}