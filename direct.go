package main

import (
	"bufio"
	"fmt"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

// ── process discovery ─────────────────────────────────────────────────────────

type gameProcess struct {
	PID       int     `json:"pid"`
	Map       string  `json:"map"`
	Port      int     `json:"port"`
	Partition int     `json:"partition"`
	CPU       float64 `json:"cpu"`
	MemMB     float64 `json:"mem_mb"`
}

var (
	portRe = regexp.MustCompile(`-Port=(\d+)`)
	partRe = regexp.MustCompile(`-PartitionIndex=(\d+)`)
)

func listGameProcesses() ([]gameProcess, error) {
	out, err := exec.Command("bash", "-c",
		`ps -eo pid,pcpu,rss,args --no-headers | grep 'DuneSandboxServer-Linux-Shipping' | grep -v grep`,
	).CombinedOutput()
	if err != nil {
		if len(strings.TrimSpace(string(out))) == 0 {
			return []gameProcess{}, nil
		}
		return nil, fmt.Errorf("ps: %w", err)
	}

	var procs []gameProcess
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line == "" {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) < 4 {
			continue
		}
		pid, _ := strconv.Atoi(fields[0])
		cpu, _ := strconv.ParseFloat(fields[1], 64)
		rssKB, _ := strconv.ParseFloat(fields[2], 64)
		args := strings.Join(fields[3:], " ")

		mapName := ""
		for i, p := range fields[3:] {
			if p == "DuneSandbox" && i+1 < len(fields[3:]) {
				mapName = fields[3+i+1]
				break
			}
		}

		port := 0
		if m := portRe.FindStringSubmatch(args); len(m) > 1 {
			port, _ = strconv.Atoi(m[1])
		}
		partition := 0
		if m := partRe.FindStringSubmatch(args); len(m) > 1 {
			partition, _ = strconv.Atoi(m[1])
		}

		procs = append(procs, gameProcess{
			PID:       pid,
			Map:       mapName,
			Port:      port,
			Partition: partition,
			CPU:       cpu,
			MemMB:     rssKB / 1024,
		})
	}
	return procs, nil
}

// ── log file discovery ────────────────────────────────────────────────────────

type logFileInfo struct {
	Name  string `json:"name"`
	SizeB int64  `json:"size_bytes"`
}

func podmanExec(args string) (string, error) {
	cmd := fmt.Sprintf("sudo -i -u %s podman exec %s %s",
		containerUser, containerName, args)
	out, err := exec.Command("bash", "-c", cmd).CombinedOutput()
	return strings.TrimSpace(string(out)), err
}

func listLogFiles() ([]logFileInfo, error) {
	out, err := podmanExec(fmt.Sprintf("ls -la %s/", containerLogPath))
	if err != nil {
		return nil, fmt.Errorf("list logs: %w (%s)", err, out)
	}
	var files []logFileInfo
	for _, line := range strings.Split(out, "\n") {
		fields := strings.Fields(line)
		if len(fields) < 9 || fields[0] == "total" || fields[0][0] == 'd' {
			continue
		}
		name := fields[len(fields)-1]
		if !strings.HasSuffix(name, ".log") {
			continue
		}
		size, _ := strconv.ParseInt(fields[4], 10, 64)
		files = append(files, logFileInfo{Name: name, SizeB: size})
	}
	return files, nil
}

// ── local command streaming ───────────────────────────────────────────────────

func localStream(cmdStr string) (<-chan string, func(), error) {
	cmd := exec.Command("bash", "-c", cmdStr) // #nosec G204 -- cmdStr is built from validated inputs
	pipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, func() {}, err
	}
	if err := cmd.Start(); err != nil {
		return nil, func() {}, err
	}
	ch := make(chan string, 256)
	go func() {
		defer close(ch)
		sc := bufio.NewScanner(pipe)
		sc.Buffer(make([]byte, 0, 256*1024), 1024*1024) // 1MB max line
		for sc.Scan() {
			ch <- sc.Text()
		}
		cmd.Wait() //nolint:errcheck
	}()
	cancel := func() {
		if cmd.Process != nil {
			cmd.Process.Kill() //nolint:errcheck
		}
		cmd.Wait() //nolint:errcheck
	}
	return ch, cancel, nil
}
