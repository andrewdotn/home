package main

import (
	"reflect"
	"testing"
)

type testInput struct {
	in        string
	want      []remote
	wantError bool
}

func TestParseRemotes(t *testing.T) {
	for _, c := range []testInput{
		{"foo", nil, true},

		{`foo	git@github.com/foo/bar.git (fetch)
foo	git@github.com/foo/bar2.git (push)`,
			nil,
			true,
		},

		{`foo	git@github.com/foo/bar.git (fetch)
foo	git@github.com/foo/bar.git (push)`,
			[]remote{
				{"foo", "git@github.com/foo/bar.git"},
			},
			false,
		},
	} {
		got, err := parseRemotes(c.in)
		checkWantErr(t, "parseRemotes", c.in, err, c.wantError)
		if !reflect.DeepEqual(got, c.want) {
			t.Errorf("parseRemotes(%q) got %v want %v",
				c.in, got, c.want)
		}
	}
}

func init() {
	userHome = "/home/testuser"
}

func TestRemoteNameSuggestions(t *testing.T) {
	for _, c := range []struct {
		url, name string
		wantError bool
	}{
		// passing an empty string should return an error
		{"", "", true},
		// For SSH, we just want the hostname and path
		{
			url:  "git@github.corp.net:Org/repo.git",
			name: "github.corp.net/Org/repo",
		},
		{
			url:  "user@github.corp.net:Org/repo.git",
			name: "github.corp.net/Org/repo",
		},
		{
			url:  "user@github.corp.net:Org/repo",
			name: "github.corp.net/Org/repo",
		},
		// An SSH remote URL may omit the username
		{
			url:  "example.org:blah",
			name: "example.org/blah",
		},
		// Similarly for https
		{
			url:  "https://github.com/Org/repo",
			name: "github.com/Org/repo",
		},
		{
			url:  "https://github.com/Org/repo.git",
			name: "github.com/Org/repo",
		},
		// There aren’t any great options for consistently naming local paths
		{
			url:  "/foo/bar/baz",
			name: "local/foo/bar/baz",
		},
		// But for fun we can include a literal $HOME in the remote name
		{
			url:  "/home/testuser/git/blah.git",
			name: "$HOME/git/blah.git",
		},
		{
			url:  "/home/testuser/git/blah",
			name: "$HOME/git/blah",
		},
		{
			url:  "/home/testuser/git/blah/",
			name: "$HOME/git/blah",
		},
	} {
		got, err := suggestedName(c.url)
		checkWantErr(t, "suggestedName", c.url, err, c.wantError)
		if got != c.name {
			t.Errorf("suggestedName(%v): got %q want %q",
				c.url, got, c.name)
		}
	}
}

func checkWantErr(t *testing.T, name string, in interface{},
	err error, wantError bool) {
	// If we wanted an error, we better have one
	if wantError && err == nil {
		t.Errorf("%s(%v) want error", name, in)
	}
	// and if we didn’t want one, we better not have gotten one
	if !wantError && err != nil {
		t.Errorf("%s(%v) unexpected %v", name, in, err)
	}
}
