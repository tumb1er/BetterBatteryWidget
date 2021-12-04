import Toybox.Lang;
using Toybox.Time;


typedef LoggedValue as Null or String or Numeric or Array or Dictionary;


(:background)
class Log {
	private var tag as String = "";
	
	public function initialize(tag as String) {
		self.tag = tag;
	}	
	(:debug)
	function debug(msg as String, arg as LoggedValue) as Void {
		if (arg instanceof Time.Moment) {
			arg = formatTime(arg as Time.Moment);
		} else if (arg instanceof Time.Duration) {
			arg = formatTime(new Time.Moment((arg as Time.Duration).value()));
		}
		System.println(Lang.format("[$1$] $2$> $3$: $4$",  [formatTime(Time.now()), tag, msg, arg]));
	}
	
	(:debug)
	function msg(msg as String) as Void {
		System.println(Lang.format("[$1$] $2$> $3$",  [formatTime(Time.now()), tag, msg]));
	}
	
	function error(msg as String, ex as Exception) as Void {
		System.println(Lang.format("[$1$] $2$> $3$:",  [formatTime(Time.now()), tag, msg]));
		ex.printStackTrace();
	}
	
}


(:background)
class LogException extends Lang.Exception {
	var msg as String = "";
	public function initialize(msg as Lang.String) {
		Exception.initialize();
		self.msg = msg;
	}

	public function toString() as Lang.String {
		return self.msg;
	}
}
