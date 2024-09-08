package ratelimit

import (
	"context"
	"errors"
	"fmt"
	"golang.org/x/time/rate"
	"strconv"
	"strings"
	"time"
)

// https://ttys3.dev/blog/serde-custom-serialization
// Marshaler 的实现一定要用普通的receiver, (即不要只实现 pointer receiver的), 因为pointer only 会导致如果是非指针形式的时候, 在序列化的时候无法调用到我们自己实现的方法.
// Unmarshaler 的实现一定要用 pointer receiver, 因为是解析数据到自身, 因此一定要修改自身, 不可修改是没有意义的.

// Marshaler should use pointer receiver, because it is used to serialize data to a byte slice. It should not modify itself. If it is not a pointer receiver, it will not be called when serializing data.
// Unmarshaler should use pointer receiver, because it is used to parse data to itself. It should modify itself. If it is not a pointer receiver, it is meaningless to not modify itself.

// RateLimitExpression is a rate limit expression
// decimal numbers, each with optional fraction and a unit suffix,
// such as "300ms", "-1.5h" or "2h45m".
// Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".
type RateLimitExpression struct {
	Count    rate.Limit
	Duration time.Duration
}

var ErrRateLimitNotAllow = errors.New("rate limit not allow")

func (r *RateLimitExpression) ToRateLimit(burst int) *rate.Limiter {
	if r.Duration <= 0 {
		return rate.NewLimiter(rate.Inf, burst)
	}
	if r.Count == rate.Inf {
		return rate.NewLimiter(rate.Inf, burst)
	}
	if r.Count <= 0 {
		return rate.NewLimiter(0, burst)
	}
	if burst <= 0 {
		return rate.NewLimiter(0, 0)
	}
	return rate.NewLimiter(rate.Every(r.Duration)*r.Count, burst)
}

// UnmarshalYAML unmarshal yaml
func (r *RateLimitExpression) UnmarshalYAML(value *yaml.Node) error {
	s := value.Value
	s = strings.ReplaceAll(strings.TrimSpace(s), " ", "")
	if s == "" || s == "inf" || s == "Inf" || s == "INF" {
		*r = RateLimitExpression{
			Count:    rate.Inf,
			Duration: 0,
		}
		return nil
	}
	// special case for rate limit of 0 and inf
	if s == "0" {
		*r = RateLimitExpression{
			Count:    rate.Limit(0),
			Duration: 0,
		}
		return nil
	}

	parts := strings.Split(s, "/")
	if len(parts) != 2 {
		return fmt.Errorf("webapis: invalid format, %q, which should be 'count/duration'", s)
	}
	count, err := strconv.ParseFloat(parts[0], 64)
	if err != nil {
		return err
	}
	du := parts[1]
	if du == "" {
		return fmt.Errorf("webapis: invalid duration, %q, which should be 'count/duration'", s)
	}
	// if du does not contain a number, add 1 to the front
	if du[0] < '0' || du[0] > '9' {
		du = "1" + du
	}
	duration, err := time.ParseDuration(du)
	if err != nil {
		return err
	}
	if duration <= 0 {
		return fmt.Errorf("webapis: invalid duration, %q, which should be greater than 0", s)
	}
	*r = RateLimitExpression{
		Count:    rate.Limit(count),
		Duration: duration,
	}
	return nil
}

// MarshalYAML RateLimitExpression
func (r RateLimitExpression) MarshalYAML() (interface{}, error) {
	if r.Count == rate.Inf {
		return "inf", nil
	}
	if r.Count == 0 {
		return "0", nil
	}
	return fmt.Sprintf("%s/%s", strconv.FormatFloat(float64(r.Count), 'f', -1, 64), r.Duration.String()), nil
}

type RateLimitInfo struct {
	RateLimit RateLimitExpression `yaml:"rateLimit"`
	LimitWait bool                `yaml:"limitWait"`
	Burst     *int                `yaml:"burst"`
}

func (r *RateLimitInfo) ToRateLimit() *rate.Limiter {
	burst := 1
	if r.Burst != nil {
		burst = *r.Burst
	}
	return r.RateLimit.ToRateLimit(burst)
}

type LimiterInfo struct {
	Limiter   *rate.Limiter
	LimitWait bool
}

func (limit *LimiterInfo) Limit(ctx context.Context) error {
	if limit.LimitWait {
		if err := limit.Limiter.Wait(ctx); err != nil {
			return err
		}
	} else {
		if !limit.Limiter.Allow() {
			return ErrRateLimitNotAllow
		}
	}
	return nil
}

func (r *RateLimitInfo) ToLimiterInfo() *LimiterInfo {
	burst := 1
	if r.Burst != nil {
		burst = *r.Burst
	}
	lim := r.RateLimit.ToRateLimit(burst)
	return &LimiterInfo{
		Limiter:   lim,
		LimitWait: r.LimitWait,
	}
}
