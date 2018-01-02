package golgi;

/**
  Error states for incorrect paths.
 **/
enum Error {
	NotFound( path : String );
	InvalidValue;
	Missing( name : String);
	MissingParam( path : String, p : String );
	TooManyValues;
}
