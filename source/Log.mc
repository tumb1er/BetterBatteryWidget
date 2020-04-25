using Toybox.Time;

(:background)
class Log {
	private var tag;
	
	function initialize(tag) {
		self.tag = tag;
	}
	
	(:debug)
	function child(tag) {
		return new Log(Lang.format("$1$.$2$", [self.tag, tag]));
	}
	
	(:release) 
	function child(tag) {
		return self;
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
	
	(:release)
	function debug(msg, params) {}
	
	(:debug)
	function msg(msg) {
		System.println(Lang.format("[$1$] $2$> $3$",  [formatTime(Time.now()), tag, msg]));
	}
	
	(:release)
	function msg(msg) {}
	
	function error(msg, ex) {
		System.println(Lang.format("[$1$] $2$> $3$: $4$",  [formatTime(Time.now()), tag, msg, ex]));
	}
	
}