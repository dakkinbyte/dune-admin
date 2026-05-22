package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

// ── mq-game publisher ─────────────────────────────────────────────────────────

var (
	mqGameConn *amqp.Connection
	mqGameCh   *amqp.Channel
	mqGameMu   sync.Mutex
	mqGameAddr = "10.43.48.246:5672" // ClusterIP, TLS
)

func mqGameChannel() (*amqp.Channel, error) {
	mqGameMu.Lock()
	defer mqGameMu.Unlock()

	// Return healthy existing channel.
	if mqGameCh != nil && !mqGameCh.IsClosed() {
		return mqGameCh, nil
	}

	// (Re)connect.
	if mqGameConn != nil && !mqGameConn.IsClosed() {
		mqGameConn.Close()
	}

	cfg := amqp.Config{
		SASL:            []amqp.Authentication{&amqp.PlainAuth{Username: capUser, Password: capPass}},
		Vhost:           "/",
		Heartbeat:       10 * time.Second,
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // #nosec G402 -- internal RabbitMQ tunnel over SSH, self-signed cert
		Dial: func(_, _ string) (net.Conn, error) {
			if globalSSH == nil {
				return nil, fmt.Errorf("SSH not connected")
			}
			return globalSSH.Dial("tcp", mqGameAddr)
		},
	}
	conn, err := amqp.DialConfig("amqps://"+mqGameAddr+"/", cfg)
	if err != nil {
		return nil, fmt.Errorf("mq-game connect: %w", err)
	}
	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("mq-game channel: %w", err)
	}
	mqGameConn = conn
	mqGameCh = ch
	return ch, nil
}

// publishNotification sends a CourierNotification to the mq-game notifications
// exchange. routingKey controls which server queues receive it ("PlayerOnlineState",
// "#" for broadcast, etc.). keywords controls what the game client does with it.
func publishNotification(routingKey string, keywords []string, content string) error {
	ch, err := mqGameChannel()
	if err != nil {
		return err
	}

	// Inner payload (content field of the courier).
	inner, _ := json.Marshal(map[string]any{
		"RoutingInfo": map[string]any{"Keywords": keywords},
		"content":     content,
		"SenderId":    1,
	})

	// Outer CourierNotification envelope.
	outer, _ := json.Marshal(map[string]any{
		"Type":    "CourierNotification",
		"content": string(inner),
	})

	err = ch.Publish(
		"notifications", // exchange
		routingKey,      // routing key
		false,           // mandatory
		false,           // immediate
		amqp.Publishing{
			ContentType: "Content",
			Body:        outer,
		},
	)
	if err != nil {
		// Channel may have died — clear it so next call reconnects.
		mqGameMu.Lock()
		mqGameCh = nil
		mqGameMu.Unlock()
		return fmt.Errorf("publish: %w", err)
	}
	return nil
}

// ── HTTP handler ──────────────────────────────────────────────────────────────

// handleNotify publishes an in-game notification via mq-game.
//
// POST /api/v1/notify
//
//	{
//	  "routing_key": "PlayerOnlineState",  // optional, default "#"
//	  "keywords":    ["PlayerOnlineState"],  // optional, default ["AdminMessage"]
//	  "content":     "Hello World!"
//	}
func handleNotify(w http.ResponseWriter, r *http.Request) {
	var req struct {
		RoutingKey string   `json:"routing_key"`
		Keywords   []string `json:"keywords"`
		Content    string   `json:"content"`
	}
	if err := decode(r, &req); err != nil {
		jsonErr(w, err, 400)
		return
	}
	if req.Content == "" {
		jsonErr(w, fmt.Errorf("content required"), 400)
		return
	}
	if req.RoutingKey == "" {
		req.RoutingKey = "PlayerOnlineState"
	}
	if len(req.Keywords) == 0 {
		req.Keywords = []string{"PlayerOnlineState"}
	}

	if err := publishNotification(req.RoutingKey, req.Keywords, req.Content); err != nil {
		jsonErr(w, err, 500)
		return
	}
	jsonOK(w, map[string]string{"ok": "notification sent"})
}
