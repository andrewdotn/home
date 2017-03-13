package main

import (
	"flag"
	"fmt"
	"log"
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
var gitRegex = regexp.MustCompile(
	"^[a-zA-Z0-9]+@([a-zA-Z0-9.]+):([a-zA-Z0-9./]+)$")

// Compute a precise remote name based on the URL
func suggestedName(url string) (string, error) {
	url = strings.TrimSpace(url)
	if len(url) == 0 {
		return "", fmt.Errorf("empty remote URL")
	}

	if strings.HasPrefix(url, "https://") {
		ret := url[len("https://"):]
		if strings.HasSuffix(url, ".git") {
			ret = ret[:len(ret)-4]
		}
		return ret, nil
	}

	if groups := gitRegex.FindStringSubmatch(url); groups != nil {
		ret := groups[1] + "/" + groups[2]
		if strings.HasSuffix(ret, ".git") {
			ret = ret[:len(ret)-4]
		}
		return ret, nil
	}

	if strings.HasPrefix(url, userHome) {
		return "$HOME" + url[len(userHome):], nil
	}
	if strings.HasPrefix(url, "/") {
		return "local" + url, nil
	}
	return url, nil
}

func run(cmd ...string) (string, error) {
	git_cmd := exec.Command(cmd[0], cmd[1:]...)
	output, err := git_cmd.CombinedOutput()
	s := string(output)
	return s, err
}
