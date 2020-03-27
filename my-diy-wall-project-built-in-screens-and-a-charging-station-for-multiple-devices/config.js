/* Magic Mirror Config Sample
 *
 * By Michael Teeuw http://michaelteeuw.nl
 * MIT Licensed.
 *
 * For more information how you can configurate this file
 * See https://github.com/MichMich/MagicMirror#configuration
 *
 */

var config = {
	address: "localhost", // Address to listen on, can be:
	                      // - "localhost", "127.0.0.1", "::1" to listen on loopback interface
	                      // - another specific IPv4/6 to listen on a specific interface
	                      // - "", "0.0.0.0", "::" to listen on any interface
	                      // Default, when address config is left out, is "localhost"
	port: 8080,
	ipWhitelist: [],                                       // Set [] to allow all IP addresses
	                                                       // or add a specific IPv4 of 192.168.1.5 :
	                                                       // ["127.0.0.1", "::ffff:127.0.0.1", "::1", "::ffff:192.168.1.5"],
	                                                       // or IPv4 range of 192.168.3.0 --> 192.168.3.15 use CIDR format :
	                                                       // ["127.0.0.1", "::ffff:127.0.0.1", "::1", "::ffff:192.168.3.0/28"],

	language: "nb",
	timeFormat: 24,
	units: "metric",

	modules:
	[
	//	{
	//		module: "alert",
	//	},
	//	{
	//		module: "updatenotification",
	//	},
		{
			module: 'MMM-CalendarExt2',
			config: {
			  calendars : [
				{
					url: "https://www.google.com/calendar/ical/flemmingss%40gmail.com/private-00000000000000000000000000000000/basic.ics",
					name: "flemming_privat",
					className: "flemming_privat",
				},
				{
					name: "flemming_jobb",
					url: "https://calendar.google.com/calendar/ical/00000000000000000000000000%40group.calendar.google.com/private-0000000000000000000000000000000/basic.ics",
					className: "flemming_jobb",
				},
				{
					name: "flemming_facebook",
					url: "https://www.facebook.com/ical/u.php?uid=000000000&key=0000000000000000",
					className: "facebook",
				},
			  ],
			  views: [
				{
				  mode: "month",
				  position: "fullscreen_below",
				},
			  ],
			  scenes: [
				{
				  name: "DEFAULT",
				},
			  ],
			},
		  },
		
	]
};

/*************** DO NOT EDIT THE LINE BELOW ***************/
if (typeof module !== "undefined") {module.exports = config;}
