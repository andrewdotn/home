// Find all notes.txt files in ~, parse out the entries, and sort them by date
package allnotes

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path"
	"sort"
	"strings"
	"time"
)

func Main() {
	notes := make([]*note, 0)
	for _, path := range filterNotes(listNotes()) {
		n := makeNote(path)
		notes = append(notes, &n)
	}
	entries := allEntries(notes)
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].when.Before(entries[j].when)
	})
	entries = mergeDuplicates(entries)
	for _, e := range entries {
		fmt.Printf("%s %s\n\n%s\n\n",
			e.when.Format("2006-01-02 Mon 15:04:05 -0700"),
			e.stringPaths(), e.text)
	}
}

type note struct {
	path    string
	text    string
	entries []entry
}

type entry struct {
	when       time.Time
	text       string
	note       *note
	otherPaths []string // for storing duplicate locations
}

func makeNote(path string) note {
	n := note{path: path}
	n.load()
	n.split()
	return n
}

func (n *note) load() {
	b, err := ioutil.ReadFile(n.path)
	if err != nil {
		log.Fatal(err)
	}
	n.text = string(b)
}

func (n *note) addEntry(e *entry) {
	e.note = n
	n.entries = append(n.entries, *e)
}

// Parse the note and store the results in note.entries
func (n *note) split() {
	matches := datePattern.FindAllStringSubmatchIndex(n.text, -1)

	if len(matches) == 0 {
		log.Printf("%s does not have any dates", n.path)
		return
	} else if matches[0][0] != 0 {
		log.Printf("%s does not start with date", n.path)
	}

	for i, m := range matches {
		var layout = ""
		datePart := n.text[m[0]:m[1]]
		for j := 2; j < len(m); j += 2 {
			if m[j] != -1 {
				layout = dateFormats[(j-1)/2].layout
			}
		}
		if layout == "" {
			log.Fatalf("No layout found for %s", datePart)
		}
		date, err := time.Parse(layout, datePart)
		if err != nil {
			log.Fatalf("Failed to parse %s in %s", datePart, n.path)
		}

		var end int
		if i+1 < len(matches) {
			end = matches[i+1][0]
		} else {
			end = len(n.text)
		}
		body := n.text[m[1]:end]
		body = strings.TrimSpace(body)

		e := entry{
			when: date,
			text: body,
		}
		n.addEntry(&e)
	}
}

func allEntries(l []*note) []entry {
	ret := make([]entry, 0)
	for _, n := range l {
		ret = append(ret, n.entries...)
	}
	return ret
}

func filterNotes(l []string) []string {

	ret := make([]string, 0)

	for _, n := range l {
		if !validNoteFile(n) {
			continue
		}
		ret = append(ret, n)
	}
	return ret
}

func validNoteFile(path string) bool {
	if _, err := os.Stat(path); err != nil {
		return false
	}

	return strings.HasPrefix(path, home) &&
		(strings.HasSuffix(path, "/notes.txt") ||
			strings.HasSuffix(path, "/log.txt")) &&
		!strings.HasPrefix(path, home+"/Library/Python/")
}

func listNotes() []string {
	// Using a map as a set here
	s := make(map[string]bool, 0)

	for _, f := range []string{"notes.txt", "log.txt"} {
		cmds := [][]string{
			{"mdfind", "-0", "-name", f},
			{"locate", "-0", f},
		}

		locatorRan := false
		var err error

		for _, cmd := range cmds {
			cmd := exec.Command(cmd[0], cmd[1:]...)
			var b []byte
			b, err = cmd.Output()
			if err != nil {
				if errors.Is(err, exec.ErrNotFound) {
					continue
				} else {
					log.Fatal(err)
				}
			}
			p := string(b)
			for _, line := range strings.Split(p, "\000") {
				s[line] = true
			}

			locatorRan = true
			// macOS also has locate(!) but it is quite slow so we skip it if mdfind worked
			break
		}

		if !locatorRan {
			log.Fatal(err)
		}
	}

	// mdfind can be unreliable, so ~/allnotes.index is a backup
	indexPath := path.Join(home, "allnotes.index")
	if stat, err := os.Stat(indexPath); err == nil && !stat.IsDir() {
		b, err := ioutil.ReadFile(indexPath)
		if err != nil {
			log.Fatal(err)
		}
		p := string(b)

		for _, line := range strings.Split(p, "\n") {
			p := path.Join(home, line)
			s[p] = true
		}
	}

	r := make([]string, 0, len(s))
	for k := range s {
		if !strings.Contains(k, "access.log") {
			r = append(r, k)
		}
	}
	return r
}

// If two adjacent entries have the same contents, it’s likely the file was
// copied. Only include the first e, but add the second e’s path to
// the displayed path list
func mergeDuplicates(entries []entry) []entry {
	ret := []entry{entries[0]}
	last := &ret[0]
	for i := 1; i < len(entries); i++ {
		if last.sameContent(entries[i]) {
			last.addPath(entries[i])
		} else {
			ret = append(ret, entries[i])
			last = &ret[len(ret)-1]
		}
	}
	return ret
}

func (e1 entry) sameContent(e2 entry) bool {
	return e1.when.Equal(e2.when) && e1.text == e2.text
}

func (e *entry) addPath(o entry) {
	e.otherPaths = append(e.otherPaths, o.note.path)
}

var home = os.Getenv("HOME")

func (e entry) stringPaths() string {
	ret := make([]string, 0)
	ret = append(ret, e.note.path)
	for _, p := range e.otherPaths {
		ret = append(ret, p)
	}
	for i := range ret {
		if strings.HasPrefix(ret[i], home) {
			ret[i] = strings.Replace(ret[i], home, "~", 1)
		}
	}
	return strings.Join(ret, ", ")
}
