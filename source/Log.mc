using Toybox.Lang;
using Toybox.Time;

(:background)
class Log {
	private var tag;
	
	function initialize(tag) {
		self.tag = tag;
	}
	
	(:debug)
	function debug(msg, arg) {
		if (arg instanceof Time.Moment) {
			arg = formatTime(arg);
		} else if (arg instanceof Time.Duration) {
			arg = formatTime(new Time.Moment(arg.value()));
		}
		System.println(Lang.format("[$1$] $2$> $3$: $4$",  [formatTime(Time.now()), tag, msg, arg]));
	}
	
	(:debug)
	function msg(msg) {
		System.println(Lang.format("[$1$] $2$> $3$",  [formatTime(Time.now()), tag, msg]));
	}
	
	function error(msg, ex) {
		System.println(Lang.format("[$1$] $2$> $3$:",  [formatTime(Time.now()), tag, msg]));
		ex.printStackTrace();
	}
	
}


(:background)
class LogException extends Lang.Exception {
	var msg;
	public function initialize(msg as Lang.String) {
		Exception.initialize();
		self.msg = msg;
	}

	public function toString() as Lang.String {
		return self.msg;
	}
}