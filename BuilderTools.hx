
class BuilderTools {
    public static function mapi<T>(arr : Array<T>, f : Int->T->T){
        var ret = [];
        for (i in 0...arr.length){
           ret.push(f(i, arr[i]));
        }
        return ret;
    }
}
