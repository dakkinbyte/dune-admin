package main

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

// dialRecordingExecutor is an Executor whose Dial records the requested address
// and then connects to a fixed target instead. It lets tests prove that HTTP
// traffic is routed through the executor: the requested address is unreachable,
// so a successful response can only have arrived via the redirected dial.
type dialRecordingExecutor struct {
	psOut    string
	target   string // real address Dial connects to, regardless of requested addr
	dialAddr string // requested address, recorded for assertions
}

func (e *dialRecordingExecutor) Exec(string) (string, error) { return e.psOut, nil }
func (e *dialRecordingExecutor) Stream(string) (<-chan string, func(), error) {
	return nil, func() {}, nil
}
func (e *dialRecordingExecutor) PipeToWriter(string, io.Writer) error { return nil }
func (e *dialRecordingExecutor) WriteFile(string, io.Reader) error    { return nil }
func (e *dialRecordingExecutor) Dial(network, addr string) (net.Conn, error) {
	e.dialAddr = addr
	return net.Dial(network, e.target)
}
func (e *dialRecordingExecutor) Close()       {}
func (e *dialRecordingExecutor) Type() string { return "ssh" }

// TestHTTPTransportVia_UsesProvidedDialer verifies the transport built by
// httpTransportVia establishes every connection through the supplied dialer,
// not via a direct dial to the request's host.
func TestHTTPTransportVia_UsesProvidedDialer(t *testing.T) {
	t.Parallel()

	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, "reached-backend")
	}))
	defer backend.Close()

	var dialedAddr string
	transport := httpTransportVia(func(network, addr string) (net.Conn, error) {
		dialedAddr = addr
		return net.Dial(network, backend.Listener.Addr().String())
	})
	client := &http.Client{Transport: transport}

	// director.invalid is unresolvable: success proves the dialer was used.
	resp, err := client.Get("http://director.invalid:11717/v0/battlegroup")
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer func() { _ = resp.Body.Close() }()
	body, _ := io.ReadAll(resp.Body)

	if string(body) != "reached-backend" {
		t.Errorf("body = %q, want %q", body, "reached-backend")
	}
	if dialedAddr != "director.invalid:11717" {
		t.Errorf("dialed addr = %q, want %q", dialedAddr, "director.invalid:11717")
	}
}

// TestNewDirectorProxy_RoutesThroughDialer verifies the /director/ reverse
// proxy strips the /director prefix and routes the upstream connection through
// the supplied dialer (the executor tunnel).
func TestNewDirectorProxy_RoutesThroughDialer(t *testing.T) {
	t.Parallel()

	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "path="+r.URL.Path)
	}))
	defer backend.Close()

	target, err := url.Parse("http://director.invalid:11717")
	if err != nil {
		t.Fatalf("parse target: %v", err)
	}
	var dialedAddr string
	handler := newDirectorProxy(target, func(network, addr string) (net.Conn, error) {
		dialedAddr = addr
		return net.Dial(network, backend.Listener.Addr().String())
	})

	req := httptest.NewRequest(http.MethodGet, "/director/v0/battlegroup", nil)
	rec := httptest.NewRecorder()
	handler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %q", rec.Code, rec.Body.String())
	}
	if got := rec.Body.String(); got != "path=/v0/battlegroup" {
		t.Errorf("backend saw %q, want %q (prefix not stripped?)", got, "path=/v0/battlegroup")
	}
	if dialedAddr != "director.invalid:11717" {
		t.Errorf("dialed addr = %q, want %q", dialedAddr, "director.invalid:11717")
	}
}

// TestDialThroughExecutor verifies the shared dialer routes through the active
// executor when set and falls back to a direct dial when it is nil.
func TestDialThroughExecutor(t *testing.T) {
	// Not parallel: mutates the globalExecutor package global.
	backend := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	defer backend.Close()
	addr := backend.Listener.Addr().String()

	saved := globalExecutor
	defer func() { globalExecutor = saved }()

	// nil executor → direct dial succeeds against the listening backend.
	globalExecutor = nil
	conn, err := dialThroughExecutor("tcp", addr)
	if err != nil {
		t.Fatalf("direct dial failed: %v", err)
	}
	_ = conn.Close()

	// executor set → unreachable addr still connects, routed through executor.
	rec := &dialRecordingExecutor{target: addr}
	globalExecutor = rec
	conn2, err := dialThroughExecutor("tcp", "director.invalid:11717")
	if err != nil {
		t.Fatalf("executor dial failed: %v", err)
	}
	_ = conn2.Close()
	if rec.dialAddr != "director.invalid:11717" {
		t.Errorf("executor dialed %q, want %q", rec.dialAddr, "director.invalid:11717")
	}
}

// TestAmpGetStatus_DirectorDialsThroughExecutor proves director enrichment in
// GetStatus reaches the director through the executor's tunnel: the configured
// director URL is unresolvable, so enrichment can only succeed via the
// executor's redirected dial.
func TestAmpGetStatus_DirectorDialsThroughExecutor(t *testing.T) {
	// Not parallel: GetStatus reads the globalDB package global.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v0/battlegroup" {
			http.NotFound(w, r)
			return
		}
		_, _ = io.WriteString(w, directorBattlegroupJSON)
	}))
	defer srv.Close()

	exec := &dialRecordingExecutor{
		psOut:  psLineFor(1001, "Overmap", 7794, 2),
		target: srv.Listener.Addr().String(),
	}
	c := &ampControl{
		container:    "AMP_X",
		useContainer: false,
		directorURL:  "http://director.invalid:11717",
	}
	status, err := c.GetStatus(t.Context(), exec)
	if err != nil {
		t.Fatalf("GetStatus: %v", err)
	}
	if len(status.Servers) != 1 {
		t.Fatalf("got %d servers, want 1", len(status.Servers))
	}
	row := status.Servers[0]
	if row.Partition != 2 || row.Sietch != "Overland" || row.Players != 5 {
		t.Errorf("row = %+v, want partition 2 sietch Overland players 5 (director enrichment via executor)", row)
	}
	if exec.dialAddr != "director.invalid:11717" {
		t.Errorf("director dialed %q, want %q (not routed through executor)", exec.dialAddr, "director.invalid:11717")
	}
}
