package mobile.macros;

import lime.utils.Log;

class GlobalMacro {
    public static function haxelibWarning():Void {
        #if android
        #if (hxluajit || hxlua)
        Log.warn('hxluajit or hxlua detected, using hxluajit or hxlua is still experimental!!');
        #elseif (linc_luajit && (hxCodec > "2.6.0"))
        Log.warn('Newer version of hxCodec with linc_luajit detected, lua will be die. Consider downgrading hxCodec to "2.6.0".');
        #elseif (linc_luajit && hxvlc)
        Log.warn('linc_luajit with hxvlc detected, lua will be die. Consider using EXPERIMENTAL_HXLUAJIT or ADVANCED_VIDEO_FUNCTIONS instead.');
        #end
        #end
    }
}