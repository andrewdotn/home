package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

func main() {
	dryRun := flag.CommandLine.Bool("dry-run", false, "")

	err := flag.CommandLine.Parse(os.Args[1:])
	if err != nil {
		log.Fatal(err)
	}

	rtext, err := run("git", "remote", "-v")
	if err != nil {
		log.Fatal(err)
	}
	robjs, err := parseRemotes(rtext)
	if err != nil {
		log.Fatal(err)
	}
	for _, r := range robjs {
		newName, err := suggestedName(r.url)
		if err != nil {
			log.Fatal(err)
		}
		if r.name != newName {
			fmt.Printf("%s → %s %s\n",
				r.name, newName, r.url)
			if !*dryRun {
				_, err := run("git", "remote", "rename",
					r.name, newName)
				if err != nil {
					log.Fatal(err)
				}
			}
		}
	}
}

type remote struct {
	name, url string
}

var reWhiteSpace = regexp.MustCompile("\\s+")

// Parse remotes from `git remote -v` output s
func parseRemotes(s string) ([]remote, error) {
	ret := make([]remote, 0)

	seen := make(map[string]string)

	for _, line := range strings.Split(s, "\n") {
		if len(strings.TrimSpace(line)) == 0 {
			continue
		}

		pieces := reWhiteSpace.Split(line, -1)
		if len(pieces) != 3 {
			return nil, fmt.Errorf("expected 3 fields: %q", line)
		}
		name, url, _ := pieces[0], pieces[1], pieces[2]

		cur_url, ok := seen[name]
		if ok && cur_url != url {
			return nil, fmt.Errorf("%s: multiple URLs", name)
		}
		if !ok {
			seen[name] = url
			ret = append(ret, remote{name, url})
		}
	}

	return ret, nil
}

var userHome = os.Getenv("HOME")

// Compute a precise remote name based on the URL
func suggestedName(path string) (string, error) {
	u, err := url.Parse(path)
	if err != nil {
		// Didn’t parse as a normal URL, fall back
		var err2 error
		u, err2 = gitPathToUrl(path)
		if err2 != nil {
			return "", fmt.Errorf("%s; then %s", err, err2)
		}
	}

	if len(u.String()) == 0 {
		return "", fmt.Errorf("empty remote URL")
	}

	// Strip trailing slashes, which are invalid in git remote names
	cleanPath := func(s string) string {
		return strings.TrimSuffix(s, "/")
	}

	if u.Host == "" {
		if (u.Scheme != "") {
			return u.Scheme + "/" + u.Opaque, nil
		}
		if strings.HasPrefix(u.Path, userHome) {
			return "$HOME" + cleanPath(u.Path[len(userHome):]), nil
		}
		if strings.HasPrefix(u.Path, "/") {
			return "local" + cleanPath(u.Path), nil
		}
	} else {
		if strings.HasSuffix(u.Path, ".git") {
			u.Path = u.Path[:len(u.Path)-4]
		}
	}

	return u.Host + u.Path, nil
}

var gitRegex = regexp.MustCompile(
	"^([^@]*@)?([^@/]+):(.*)")

// Turn git-specific paths like foo@host:bar into URLs
func gitPathToUrl(path string) (*url.URL, error) {
	if groups := gitRegex.FindStringSubmatch(path); groups != nil {
		return &url.URL{
			Host: groups[2],
			Path: "/" + groups[3],
		}, nil
	}
	return &url.URL{}, fmt.Errorf("Unknown format %v", path)
}

func run(cmd ...string) (string, error) {
	git_cmd := exec.Command(cmd[0], cmd[1:]...)
	output, err := git_cmd.CombinedOutput()
	s := string(output)
	if err != nil {
		err = fmt.Errorf("%s: %s", err.Error(), s)
	}
	return s, err
}
