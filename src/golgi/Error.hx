package golgi;

enum Error {
	NotFound( path : String );
	InvalidValue;
	Missing( name : String);
	MissingParam( path : String, p : String );
	TooManyValues;
}
