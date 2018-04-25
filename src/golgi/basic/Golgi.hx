package golgi.basic;
import golgi.basic.Api as BasicApi;
import golgi.MetaGolgi;

class Golgi<TApi : BasicApi, TResult> extends golgi.Golgi<{}, TApi, TResult, MetaGolgi<{}, TResult>>{}
