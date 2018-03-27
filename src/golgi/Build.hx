import haxe.macro.Field;
class Build {
    macro public static function golgi() : Array<Field> {
        return builder.Builder.build();
    }
}
