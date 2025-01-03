package main

import (
	"sync"
	"time"
)

var (
	condMapMu sync.Mutex
	condMap   = make(map[string]*sync.Cond)
)

func getCondByID(id string) *sync.Cond {
	condMapMu.Lock()
	defer condMapMu.Unlock()
	cond, ok := condMap[id]
	if !ok {
		cond = sync.NewCond(&sync.Mutex{})
		condMap[id] = cond
	}
	return cond
}

func waitCondWithTimeout(cond *sync.Cond, timeout time.Duration) bool {
	done := make(chan struct{})
	go func() {
		cond.L.Lock()
		cond.Wait()
		cond.L.Unlock()
		close(done)
	}()
	select {
	case <-done:
		return true
	case <-time.After(timeout):
		return false
	}
}

func waitCondWithTimeoutByID(id string, timeout time.Duration) {
	cond := getCondByID(id)
	waitCondWithTimeout(cond, timeout)
}

func signalCondByID(id string) {
	cond := getCondByID(id)
	cond.Signal()
}
