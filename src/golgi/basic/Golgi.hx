package golgi.basic;
import golgi.basic.Api as BasicApi;
import golgi.MetaGolgi;
import adadt.Adadt;

class Golgi<TApi : BasicApi> extends golgi.Golgi<{}, TApi, Adadt<TApi>, MetaGolgi<{}, Adadt<TApi>>>{}
