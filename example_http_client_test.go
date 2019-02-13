package retry_test

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"time"

	. "github.com/kamilsk/retry/v3"
	. "github.com/kamilsk/retry/v3/strategy"
)

type client struct {
	base       *http.Client
	strategies []Strategy
}

func New(timeout time.Duration, strategies ...Strategy) *client {
	return &client{
		base:       &http.Client{Timeout: timeout},
		strategies: strategies,
	}
}

func (c *client) Get(deadline <-chan struct{}, url string) (*http.Response, error) {
	var response *http.Response
	err := Retry(deadline, func(uint) error {
		resp, err := c.base.Get(url)
		if err != nil {
			return err
		}
		response = resp
		return nil
	}, c.strategies...)
	return response, err
}

// This example shows how to extend standard http.Client with retry under the hood.
func Example_httpClient() {
	var attempts int32 = 2
	ts := httptest.NewServer(http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		if atomic.CompareAndSwapInt32(&attempts, 0, -1) {
			_, _ = rw.Write([]byte("success"))
			return
		}
		atomic.AddInt32(&attempts, -1)
		time.Sleep(100 * time.Millisecond)
	}))
	defer ts.Close()

	cl := New(10*time.Millisecond, Limit(uint(attempts)+1))
	resp, err := cl.Get(WithTimeout(time.Second), ts.URL)

	fmt.Printf("response: %s, error: %+v \n", func() string {
		b, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return err.Error()
		}
		return string(b)
	}(), err)
	// Output: response: success, error: <nil>
}
