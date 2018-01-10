package golgi;

/**
  Error states for incorrect paths.
 **/
enum Error {
	NotFound( path : String );
	InvalidValue(name : String);
	InvalidValueParam(name : String);
	Missing( name : String);
	MissingParam( name : String);
	TooManyValues;
}
