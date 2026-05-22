package main

import (
	"archive/zip"
	"bytes"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type backupFile struct {
	Name     string `json:"name"`
	SizeB    int64  `json:"size_bytes"`
	Modified string `json:"modified"`
	HasYAML  bool   `json:"has_yaml"`
}

var bgCmdAllowlist = map[string]bool{
	"start": true, "stop": true, "restart": true,
	"update": true, "backup": true,
	// restore handled separately via handleBGRestore
}

func handleBGStatus(w http.ResponseWriter, r *http.Request) {
	if globalSSH == nil {
		jsonErr(w, fmt.Errorf("SSH not connected"), 503)
		return
	}

	bgName := strings.TrimPrefix(globalPodNS, "funcom-seabass-")

	// Battlegroup-level: title, phase, database phase.
	bgOut, _ := sshExec(fmt.Sprintf(
		`sudo kubectl get battlegroups -n %s -o jsonpath="{.items[0].spec.title}|{.items[0].status.phase}|{.items[0].status.database.phase}" 2>/dev/null`,
		globalPodNS))

	bgParts := strings.SplitN(strings.TrimSpace(bgOut), "|", 3)
	bg := map[string]string{
		"name":     bgName,
		"title":    safeIdx(bgParts, 0),
		"phase":    safeIdx(bgParts, 1),
		"database": safeIdx(bgParts, 2),
	}

	// Per-server stats: map, sietch, dimension, partition, gamePhase, ready, players.
	ssOut, _ := sshExec(fmt.Sprintf(
		"sudo kubectl get serverstats -n %s -o jsonpath='{range .items[*]}{.spec.area.map}|{.spec.area.sietch}|{.spec.area.dimension}|{.spec.area.partition}|{.status.runtime.gamePhase}|{.status.runtime.ready}|{.status.runtime.players}{\"\\n\"}{end}' 2>/dev/null",
		globalPodNS))

	type serverRow struct {
		Map       string `json:"map"`
		Sietch    string `json:"sietch"`
		Dimension int    `json:"dimension"`
		Partition int    `json:"partition"`
		Phase     string `json:"phase"`
		Ready     bool   `json:"ready"`
		Players   int    `json:"players"`
	}
	var servers []serverRow
	for _, line := range strings.Split(strings.TrimSpace(ssOut), "\n") {
		if line == "" {
			continue
		}
		p := strings.SplitN(line, "|", 7)
		if len(p) < 7 {
			continue
		}
		dim, _ := strconv.Atoi(p[2])
		part, _ := strconv.Atoi(p[3])
		players, _ := strconv.Atoi(p[6])
		servers = append(servers, serverRow{
			Map:       p[0],
			Sietch:    p[1],
			Dimension: dim,
			Partition: part,
			Phase:     p[4],
			Ready:     p[5] == "true",
			Players:   players,
		})
	}
	sort.Slice(servers, func(i, j int) bool { return servers[i].Map < servers[j].Map })
	if servers == nil {
		servers = []serverRow{}
	}

	jsonOK(w, map[string]any{"battlegroup": bg, "servers": servers})
}

func safeIdx(s []string, i int) string {
	if i < len(s) {
		return s[i]
	}
	return ""
}

func handleBGExec(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Cmd string `json:"cmd"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if !bgCmdAllowlist[req.Cmd] {
		jsonErr(w, fmt.Errorf("unknown command %q", req.Cmd), 400)
		return
	}

	bgName := strings.TrimPrefix(globalPodNS, "funcom-seabass-")
	ns := globalPodNS

	var out string
	var err error

	switch req.Cmd {
	case "start":
		out, err = sshExec(fmt.Sprintf(
			`sudo kubectl patch battlegroup %s -n %s --type=merge -p '{"spec":{"stop":false}}' 2>&1 && echo "Battlegroup starting"`,
			bgName, ns))
	case "stop":
		out, err = sshExec(fmt.Sprintf(
			`sudo kubectl patch battlegroup %s -n %s --type=merge -p '{"spec":{"stop":true}}' 2>&1 && echo "Battlegroup stopping"`,
			bgName, ns))
	case "restart":
		out, err = sshExec(fmt.Sprintf(
			`sudo kubectl patch battlegroup %s -n %s --type=merge -p '{"spec":{"stop":true}}' 2>/dev/null && sleep 5 && sudo kubectl patch battlegroup %s -n %s --type=merge -p '{"spec":{"stop":false}}' 2>/dev/null && echo "Battlegroup restarting"`,
			bgName, ns, bgName, ns))
	default:
		// update/backup/restore stay on the script — complex operations.
		out, err = sshExec(fmt.Sprintf("sudo ~/.dune/download/scripts/battlegroup.sh %s 2>&1", req.Cmd))
	}

	if err != nil {
		jsonErr(w, fmt.Errorf("exec: %w — output: %s", err, out), 500)
		return
	}
	jsonOK(w, map[string]string{"output": out})
}

func handleBGPods(w http.ResponseWriter, r *http.Request) {
	out, err := sshExec(fmt.Sprintf("sudo kubectl get pods -n %s --no-headers 2>&1", globalPodNS))
	if err != nil {
		jsonErr(w, fmt.Errorf("kubectl: %w", err), 500)
		return
	}
	lines := strings.Split(strings.TrimSpace(out), "\n")
	jsonOK(w, map[string]any{"pods": lines, "namespace": globalPodNS})
}

func bgName() string { return strings.TrimPrefix(globalPodNS, "funcom-seabass-") }

func handleBGBackupFiles(w http.ResponseWriter, r *http.Request) {
	if globalSSH == nil {
		jsonErr(w, fmt.Errorf("SSH not connected"), 503)
		return
	}
	bgDir := fmt.Sprintf("/funcom/artifacts/database-dumps/%s", bgName())
	out, _ := sshExec(fmt.Sprintf(
		`sudo ls -lt %s/ 2>/dev/null | awk '/\.backup$/{print $NF"|"$5"|"$6" "$7" "$8}'`,
		bgDir))
	// Build set of which backups have a .yaml companion.
	yamlOut, _ := sshExec(fmt.Sprintf(
		`sudo ls %s/*.backup.yaml 2>/dev/null | xargs -r -I{} basename {} .yaml`,
		bgDir))
	hasYAML := make(map[string]bool)
	for _, n := range strings.Split(strings.TrimSpace(yamlOut), "\n") {
		if n != "" {
			hasYAML[strings.TrimSpace(n)] = true
		}
	}
	var files []backupFile
	for _, line := range strings.Split(strings.TrimSpace(out), "\n") {
		if line == "" {
			continue
		}
		p := strings.SplitN(line, "|", 3)
		if len(p) < 3 {
			continue
		}
		size, _ := strconv.ParseInt(p[1], 10, 64)
		name := p[0]
		files = append(files, backupFile{Name: name, SizeB: size, Modified: p[2], HasYAML: hasYAML[name]})
	}
	if files == nil {
		files = []backupFile{}
	}
	jsonOK(w, files)
}

func handleBGBackupDownload(w http.ResponseWriter, r *http.Request) {
	if globalSSH == nil {
		jsonErr(w, fmt.Errorf("SSH not connected"), 503)
		return
	}
	filename := r.URL.Query().Get("file")
	if filename == "" || strings.ContainsAny(filename, "/\\") || !strings.HasSuffix(filename, ".backup") {
		jsonErr(w, fmt.Errorf("invalid filename"), 400)
		return
	}
	baseName := strings.TrimSuffix(filename, ".backup")
	bgDir := fmt.Sprintf("/funcom/artifacts/database-dumps/%s", bgName())

	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s.zip"`, baseName))
	w.Header().Set("Content-Type", "application/zip")

	zw := zip.NewWriter(w)
	for _, ext := range []string{".backup", ".backup.yaml"} {
		name := baseName + ext
		remotePath := bgDir + "/" + name
		exists, _ := sshExec(fmt.Sprintf("sudo test -f %s && echo yes || echo no", shellQuote(remotePath)))
		if strings.TrimSpace(exists) != "yes" {
			continue
		}
		fw, err := zw.Create(name)
		if err != nil {
			continue
		}
		if err := sshPipeToWriter(fmt.Sprintf("sudo cat %s", shellQuote(remotePath)), fw); err != nil {
			fmt.Printf("zip entry %s: %v\n", name, err)
		}
	}
	zw.Close()
}

func handleBGRestore(w http.ResponseWriter, r *http.Request) {
	if globalSSH == nil {
		jsonErr(w, fmt.Errorf("SSH not connected"), 503)
		return
	}
	var req struct {
		File string `json:"file"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.File == "" || strings.ContainsAny(req.File, "/\\") || !strings.HasSuffix(req.File, ".backup") {
		jsonErr(w, fmt.Errorf("invalid filename"), 400)
		return
	}
	// Script handles staging into PVC + DatabaseOperation creation + waiting.
	out, err := sshExec(fmt.Sprintf(
		`echo yes | sudo ~/.dune/download/scripts/battlegroup.sh import %s 2>&1`,
		shellQuote(req.File)))
	if err != nil {
		jsonErr(w, fmt.Errorf("restore failed: %w\n%s", err, out), 500)
		return
	}
	jsonOK(w, map[string]string{"output": out})
}
func sshWriteFile(remotePath string, data io.Reader) error {
	sess, err := globalSSH.NewSession()
	if err != nil {
		return err
	}
	defer sess.Close()
	stdin, err := sess.StdinPipe()
	if err != nil {
		return err
	}
	if err := sess.Start(fmt.Sprintf("sudo tee %s > /dev/null", shellQuote(remotePath))); err != nil {
		return err
	}
	if _, err := io.Copy(stdin, data); err != nil {
		return err
	}
	stdin.Close()
	return sess.Wait()
}

func handleBGBackupUpload(w http.ResponseWriter, r *http.Request) {
	if globalSSH == nil {
		jsonErr(w, fmt.Errorf("SSH not connected"), 503)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 4<<30)
	if err := r.ParseMultipartForm(64 << 20); err != nil {
		jsonErr(w, fmt.Errorf("parse form: %w", err), 400)
		return
	}
	file, header, err := r.FormFile("backup")
	if err != nil {
		jsonErr(w, fmt.Errorf("no file: %w", err), 400)
		return
	}
	defer file.Close()

	filename := header.Filename
	bgDir := fmt.Sprintf("/funcom/artifacts/database-dumps/%s", bgName())

	if strings.HasSuffix(filename, ".zip") {
		// Read zip fully (needed for zip.NewReader which requires ReaderAt + size).
		data, err := io.ReadAll(file)
		if err != nil {
			jsonErr(w, fmt.Errorf("read zip: %w", err), 400)
			return
		}
		zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
		if err != nil {
			jsonErr(w, fmt.Errorf("invalid zip: %w", err), 400)
			return
		}
		var backupName string
		for _, zf := range zr.File {
			name := filepath.Base(zf.Name)
			if strings.ContainsAny(name, "/\\") {
				continue
			}
			if !strings.HasSuffix(name, ".backup") && !strings.HasSuffix(name, ".backup.yaml") {
				continue
			}
			rc, err := zf.Open()
			if err != nil {
				continue
			}
			_ = sshWriteFile(bgDir+"/"+name, rc)
			rc.Close()
			if strings.HasSuffix(name, ".backup") && !strings.HasSuffix(name, ".yaml") {
				backupName = name
			}
		}
		if backupName == "" {
			jsonErr(w, fmt.Errorf("zip contains no .backup file"), 400)
			return
		}
		jsonOK(w, map[string]string{"name": backupName})
	} else if strings.HasSuffix(filename, ".backup") && !strings.ContainsAny(filename, "/\\") {
		if err := sshWriteFile(bgDir+"/"+filename, file); err != nil {
			jsonErr(w, fmt.Errorf("upload failed: %w", err), 500)
			return
		}
		jsonOK(w, map[string]string{"name": filename})
	} else {
		jsonErr(w, fmt.Errorf("file must be .backup or .zip"), 400)
	}
}
