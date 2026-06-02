package main

import (
	"errors"
	"testing"
)

// TestRestartProcess_ReExecSucceeds verifies that when the re-exec succeeds,
// the signal fallback is NOT invoked. Re-exec normally replaces the process
// image and never returns; a nil return models that success path without
// actually exec'ing during tests.
func TestRestartProcess_ReExecSucceeds(t *testing.T) {
	t.Parallel()

	signalled := false
	restartProcess(
		func() error { return nil },
		func() error { signalled = true; return nil },
	)
	if signalled {
		t.Error("signal fallback was called despite successful re-exec")
	}
}

// TestRestartProcess_FallsBackToSignal verifies that when re-exec fails (e.g.
// on Windows, where syscall.Exec is unsupported), the process falls back to
// signalling itself so systemd with Restart=always still restarts it.
func TestRestartProcess_FallsBackToSignal(t *testing.T) {
	t.Parallel()

	signalled := false
	restartProcess(
		func() error { return errors.New("exec unsupported") },
		func() error { signalled = true; return nil },
	)
	if !signalled {
		t.Error("signal fallback was not called after re-exec failure")
	}
}
