import Demo.DemoMeta;
class Generate {
    inline public static function str_split(str : String, sep : String) : Array<String> {
        return str.split(sep);
    }
    public static function gen_config() {
        var a = new Demo(new DemoMeta());
        var routes = Demo.dump(a);
        var locations = [];
        var init = [];
        init.push('module = require "demo";\n');
        init.push('ngx = require "ngx";');
        for (k in routes.keys()){
            var entry = k == "" ? '[""]' : '.$k';
            var location = 'location /$k {\n\t content_by_lua_block {\n'
                    + '\t\tlocal parts = module.Util.split_path(ngx.var.request_uri);\n'
                    + '\t\tlocal status, err = pcall(function() ngx.say(module.Demo.api$entry(parts, ngx.var, {})) end);\n'
                    + '\t\tif (err) then module.Util.error(err) end;\n'
                    + '\t}\n'
                    + '}';
            locations.push(location);
        }
        sys.io.File.saveContent('tests/init.lua', init.join("\n"));
        sys.io.File.saveContent('tests/locations.conf', locations.join("\n"));
    }
    static function main() {
        gen_config();
    }
}
