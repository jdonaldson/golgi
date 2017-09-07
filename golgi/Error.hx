package golgi;

enum Error {
	NotFound( path : String );
	InvalidValue;
	Missing;
	MissingParam( path : String, p : String );
	TooManyValues;
}
