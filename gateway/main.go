package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	calc "gateway/calc_grpc"
)

var (
	basicClient    calc.BasicServiceClient
	advancedClient calc.AdvancedServiceClient
)

func initClients() {
	connA, err := grpc.NewClient("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("failed to connect to service-a: %v", err)
	}
	basicClient = calc.NewBasicServiceClient(connA)

	connB, err := grpc.NewClient("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("failed to connect to service-b: %v", err)
	}
	advancedClient = calc.NewAdvancedServiceClient(connB)
}

func parseAB(r *http.Request) (float64, float64, error) {
	a, err := strconv.ParseFloat(r.URL.Query().Get("a"), 64)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid parameter a")
	}
	b, err := strconv.ParseFloat(r.URL.Query().Get("b"), 64)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid parameter b")
	}
	return a, b, nil
}

func parseA(r *http.Request) (float64, error) {
	a, err := strconv.ParseFloat(r.URL.Query().Get("a"), 64)
	if err != nil {
		return 0, fmt.Errorf("invalid parameter a")
	}
	return a, nil
}

func writeReply(w http.ResponseWriter, result float64, grpcErr string, localErr error) {
	w.Header().Set("Content-Type", "application/json")
	if localErr != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": localErr.Error()})
		return
	}
	if grpcErr != "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": grpcErr})
		return
	}
	json.NewEncoder(w).Encode(map[string]float64{"result": result})
}

func main() {
	initClients()

	// Basic operations — Service A
	http.HandleFunc("/add", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := basicClient.Add(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/subtract", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := basicClient.Subtract(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/multiply", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := basicClient.Multiply(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/divide", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := basicClient.Divide(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})

	// Advanced operations — Service B
	http.HandleFunc("/power", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := advancedClient.Power(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/sqrt", func(w http.ResponseWriter, r *http.Request) {
		a, err := parseA(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := advancedClient.SquareRoot(context.Background(), &calc.UnaryRequest{A: a})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/factorial", func(w http.ResponseWriter, r *http.Request) {
		a, err := parseA(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := advancedClient.Factorial(context.Background(), &calc.UnaryRequest{A: a})
		writeReply(w, resp.Result, resp.Error, nil)
	})
	http.HandleFunc("/log", func(w http.ResponseWriter, r *http.Request) {
		a, b, err := parseAB(r)
		if err != nil { writeReply(w, 0, "", err); return }
		resp, _ := advancedClient.Log(context.Background(), &calc.BinaryRequest{A: a, B: b})
		writeReply(w, resp.Result, resp.Error, nil)
	})

	log.Println("[gateway] running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
