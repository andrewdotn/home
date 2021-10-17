package allnotes

import (
	"log"
	"regexp"
)

type dateFormat struct {
	layout string // what time.Parse needs later
	re     string // the regexp to pick it out of a large file
}

const hhmmss = "[0-9]{2}:[0-9]{2}:[0-9]{2}"

var dateFormats []dateFormat = []dateFormat{
	dateFormat{
		"Mon  2 Jan 2006 15:04:05 PM MST",
		"[A-Z][a-z]{2} [0-9 ][0-9] [A-Z][a-z]{2} [0-9]{4}" +
			" " + hhmmss + " [AP]M [A-Z]+",
	},
	dateFormat{
		"Mon  2 Jan 2006 15:04:05 MST",
		"[A-Z][a-z]{2} [0-9 ][0-9] [A-Z][a-z]{2} [0-9]{4}" +
			" " + hhmmss + " [A-Z]+",
	},
	dateFormat{
		"Mon Jan  2 15:04:05 MST 2006",
		"[A-Z][a-z]{2} [A-Z][a-z]{2} [0-9 ][0-9]" +
			" " + hhmmss + " [A-Z]+ [0-9]{4}",
	},
	dateFormat{
		"Mon Jan  2 15:04:05 -0600 2006",
		"[A-Z][a-z]{2} [A-Z][a-z]{2} [0-9 ][0-9]" +
			" " + hhmmss + " [+-][0-9]{4} [0-9]{4}",
	},
}

func init() {
	checkDateFormats()
}

// Every layout pattern must be matched by the associated regexp
func checkDateFormats() {
	for _, d := range dateFormats {
		re := regexp.MustCompile("^" + d.re + "$")
		if !re.MatchString(d.layout) {
			log.Fatalf("Date format %s does not match %s",
				d.layout, d.re)
		}
	}
}

func combinedRegex(l []dateFormat) *regexp.Regexp {
	ret := "(?m:"
	for i, n := range l {
		if i > 0 {
			ret += "|"
		}
		ret += "(^" + n.re + ")"
	}
	ret += ")"
	return regexp.MustCompile(ret)
}

var datePattern = combinedRegex(dateFormats)
