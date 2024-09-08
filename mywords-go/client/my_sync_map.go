package client

import (
	"mywords/model/mtype"
	"sync"
)

type MySyncMap[T any] struct {
	data map[string]T
	mux  sync.RWMutex
}

func (m *MySyncMap[T]) CopyData() map[string]T {
	m.mux.RLock()
	defer m.mux.RUnlock()
	data := make(map[string]T, len(m.data))
	for k, v := range m.data {
		data[k] = v
	}
	return data
}

func (m *MySyncMap[T]) Get(key string) (T, bool) {
	m.mux.RLock()
	defer m.mux.RUnlock()
	v, ok := m.data[key]
	return v, ok

}

func (m *MySyncMap[T]) Set(key string, value T) {
	m.mux.Lock()
	defer m.mux.Unlock()
	m.data[key] = value
}

func (m *MySyncMap[T]) Replace(data map[string]T) {
	m.mux.Lock()
	defer m.mux.Unlock()
	m.data = data

}

func (m *MySyncMap[T]) Delete(key string) {
	m.mux.Lock()
	defer m.mux.Unlock()
	delete(m.data, key)
}

func (m *MySyncMap[T]) Len() int {
	m.mux.RLock()
	defer m.mux.RUnlock()
	return len(m.data)
}

func (m *MySyncMap[T]) Range(f func(key string, value T) bool) {
	m.mux.RLock()
	defer m.mux.RUnlock()
	for k, v := range m.data {
		if !f(k, v) {
			break
		}
	}
}

func NewMySyncMap[T any]() *MySyncMap[T] {
	return &MySyncMap[T]{
		data: make(map[string]T),
	}
}

type MySyncMapMap[K string | mtype.WordKnownLevel, T any] struct {
	mux  sync.RWMutex
	data map[string]map[K]T
}

func (m *MySyncMapMap[K, T]) Len() int {
	m.mux.RLock()
	defer m.mux.RUnlock()
	return len(m.data)

}

func NewSyncMapMap[K string | mtype.WordKnownLevel, T any]() *MySyncMapMap[K, T] {
	return &MySyncMapMap[K, T]{
		mux:  sync.RWMutex{},
		data: make(map[string]map[K]T),
	}
}

func (m *MySyncMapMap[K, T]) Replace(data map[string]map[K]T) {
	m.mux.Lock()
	defer m.mux.Unlock()
	m.data = data
}

func (m *MySyncMapMap[K, T]) Set(key string, key2 K, value T) {
	m.mux.Lock()
	defer m.mux.Unlock()
	if m.data[key] == nil {
		m.data[key] = make(map[K]T)
	}
	m.data[key][key2] = value
}

func (m *MySyncMapMap[K, T]) CopyData() map[string]map[K]T {
	m.mux.RLock()
	defer m.mux.RUnlock()
	data := make(map[string]map[K]T, len(m.data))
	for k, v := range m.data {
		if _, ok := data[k]; !ok {
			data[k] = make(map[K]T)
		}
		for k2, v2 := range v {
			data[k][k2] = v2
		}
	}
	return data
}

// AllKeys
func (m *MySyncMapMap[K, T]) AllKeys() []string {
	m.mux.RLock()
	defer m.mux.RUnlock()
	keys := make([]string, 0, len(m.data))
	for k := range m.data {
		keys = append(keys, k)
	}
	return keys

}
func (m *MySyncMapMap[K, T]) Get(key string, key2 K) (T, bool) {
	m.mux.RLock()
	defer m.mux.RUnlock()
	v, ok := m.data[key][key2]

	return v, ok
}

func (m *MySyncMapMap[K, T]) GetMapByKey(key string) (map[K]T, bool) {
	m.mux.RLock()
	defer m.mux.RUnlock()
	data := make(map[K]T)
	dataMap, ok := m.data[key]
	if !ok {
		return data, false
	}
	for k, v := range dataMap {
		data[k] = v
	}
	return data, true
}
