package main

import (
	"context"
	"errors"
	"io"
	"net"
	"strings"
	"testing"
)

type fakeAMPExecutor struct {
	out string
	err error
	cmd string
}

// fnExecutor routes each Exec call through a provided function, allowing
// tests to return different output for different commands.
type fnExecutor struct {
	fn func(cmd string) (string, error)
}

func (f *fnExecutor) Exec(cmd string) (string, error) { return f.fn(cmd) }
func (f *fnExecutor) Stream(string) (<-chan string, func(), error) {
	return nil, func() {}, nil
}
func (f *fnExecutor) PipeToWriter(string, io.Writer) error { return nil }
func (f *fnExecutor) WriteFile(string, io.Reader) error    { return nil }
func (f *fnExecutor) Dial(string, string) (net.Conn, error) {
	return nil, nil
}
func (f *fnExecutor) Close()       {}
func (f *fnExecutor) Type() string { return "local" }

func (f *fakeAMPExecutor) Exec(cmd string) (string, error) {
	f.cmd = cmd
	return f.out, f.err
}
func (f *fakeAMPExecutor) Stream(string) (<-chan string, func(), error) {
	return nil, func() {}, nil
}
func (f *fakeAMPExecutor) PipeToWriter(string, io.Writer) error { return nil }
func (f *fakeAMPExecutor) WriteFile(string, io.Reader) error    { return nil }
func (f *fakeAMPExecutor) Dial(string, string) (net.Conn, error) {
	return nil, nil
}
func (f *fakeAMPExecutor) Close()       {}
func (f *fakeAMPExecutor) Type() string { return "local" }

func TestParseAMPGameProcess(t *testing.T) {
	t.Parallel()

	line := "123 /srv/DuneSandboxServer-Linux-Shipping DuneSandbox HaggaBasinS -Port=7777 -PartitionIndex=3"
	got, ok := parseAMPGameProcess(line)
	if !ok {
		t.Fatalf("expected line to parse")
	}
	if got.pid != 123 || got.mapName != "HaggaBasinS" || got.port != 7777 || got.partition != 3 {
		t.Fatalf("unexpected parsed process: %+v", got)
	}

	if _, ok := parseAMPGameProcess("garbage"); ok {
		t.Fatalf("expected malformed line to be rejected")
	}
}

func TestListGameProcesses(t *testing.T) {
	t.Parallel()

	ctrl := &ampControl{}
	exec := &fakeAMPExecutor{
		out: "100 one DuneSandbox MapA -Port=7001 -PartitionIndex=1\nbad\n200 two DuneSandbox MapB -Port=7002",
	}
	procs, err := ctrl.listGameProcesses(exec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(procs) != 2 {
		t.Fatalf("expected 2 parsed processes, got %d", len(procs))
	}
	if procs[0].pid != 100 || procs[0].mapName != "MapA" || procs[0].port != 7001 || procs[0].partition != 1 {
		t.Fatalf("unexpected first process: %+v", procs[0])
	}
	if procs[1].pid != 200 || procs[1].mapName != "MapB" || procs[1].port != 7002 || procs[1].partition != 0 {
		t.Fatalf("unexpected second process: %+v", procs[1])
	}
	if exec.cmd == "" {
		t.Fatalf("expected process listing command to be executed")
	}
}

func TestListGameProcesses_EmptyOnExecErrorWithoutOutput(t *testing.T) {
	t.Parallel()

	ctrl := &ampControl{}
	exec := &fakeAMPExecutor{err: errors.New("ps failed")}
	procs, err := ctrl.listGameProcesses(exec)
	if err != nil {
		t.Fatalf("expected no error when exec fails without output, got %v", err)
	}
	if len(procs) != 0 {
		t.Fatalf("expected empty process list, got %+v", procs)
	}
}

// TestAmpDiscoverIniDir_PrefersUE5SavedPath verifies that when
// ue5-saved/UserSettings/UserGame.ini exists (install.sh layout),
// DiscoverIniDir returns that sub-directory rather than the base state dir.
func TestAmpDiscoverIniDir_PrefersUE5SavedPath(t *testing.T) {
	t.Parallel()

	exec := &fnExecutor{fn: func(cmd string) (string, error) {
		if strings.Contains(cmd, "ue5-saved/UserSettings") {
			return "yes\n", nil
		}
		return "no\n", nil
	}}
	ctrl := &ampControl{instance: "TestInst", ampUser: "amp"}

	dir, err := ctrl.DiscoverIniDir(context.Background(), exec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "/home/amp/.ampdata/instances/TestInst/duneawakening/server/state/ue5-saved/UserSettings"
	if dir != want {
		t.Errorf("got %q, want %q", dir, want)
	}
}

// TestAmpDiscoverIniDir_FallsBackToState verifies that when ue5-saved/UserSettings
// does not have a UserGame.ini, DiscoverIniDir returns the base state directory.
func TestAmpDiscoverIniDir_FallsBackToState(t *testing.T) {
	t.Parallel()

	exec := &fnExecutor{fn: func(cmd string) (string, error) {
		return "no\n", nil
	}}
	ctrl := &ampControl{instance: "TestInst", ampUser: "amp"}

	dir, err := ctrl.DiscoverIniDir(context.Background(), exec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "/home/amp/.ampdata/instances/TestInst/duneawakening/server/state"
	if dir != want {
		t.Errorf("got %q, want %q", dir, want)
	}
}

// TestAmpDiscoverIniDir_ExplicitConfigSkipsProbe verifies that when server_ini_dir
// is explicitly configured, DiscoverIniDir returns it without probing.
func TestAmpDiscoverIniDir_ExplicitConfigSkipsProbe(t *testing.T) {
	t.Parallel()

	exec := &fnExecutor{fn: func(cmd string) (string, error) {
		t.Error("executor must not be called when iniDir is explicitly configured")
		return "", nil
	}}
	ctrl := &ampControl{iniDir: "/custom/ini/dir"}

	dir, err := ctrl.DiscoverIniDir(context.Background(), exec)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if dir != "/custom/ini/dir" {
		t.Errorf("got %q, want %q", dir, "/custom/ini/dir")
	}
}
