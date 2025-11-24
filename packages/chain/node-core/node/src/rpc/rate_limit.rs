//! Rate limiting middleware for Ghost Chain RPC endpoints
//!
//! This module provides rate limiting functionality for the Ghost Chain RPC server.
//! It implements:
//! - Per-IP rate limiting: 100 requests/minute for public RPC
//! - Per-token rate limiting: 1000 requests/minute for authenticated requests
//! - Automatic cleanup of expired entries to prevent memory leaks
//!
//! # Rate Limit Headers
//!
//! The rate limiter provides the following HTTP headers:
//! - `X-RateLimit-Limit`: Maximum number of requests allowed in the time window
//! - `X-RateLimit-Remaining`: Number of requests remaining in the current window
//! - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets
//!
//! # Error Handling
//!
//! When rate limit is exceeded, the system should return:
//! - HTTP Status: 429 Too Many Requests
//! - Error message indicating the limit and reset time
//!
//! # Usage (jsonrpsee 0.26+)
//!
//! ```ignore
//! use jsonrpsee::server::middleware::rpc::RpcServiceBuilder;
//! use crate::rpc::{RateLimiter, RateLimitMiddleware};
//!
//! let rate_limiter = RateLimiter::new();
//! let rate_limiter2 = rate_limiter.clone();
//! 
//! // Build middleware with layer_fn
//! let middleware = RpcServiceBuilder::new()
//!     .layer_fn(move |service| RateLimitMiddleware {
//!         service,
//!         rate_limiter: rate_limiter2.clone(),
//!     });
//! ```

use std::{
    collections::HashMap,
    net::IpAddr,
    sync::{Arc, Mutex},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

const WINDOW_DURATION: Duration = Duration::from_secs(60);
#[allow(dead_code)]
const IP_RATE_LIMIT: u32 = 100;
#[allow(dead_code)]
const TOKEN_RATE_LIMIT: u32 = 1000;

#[derive(Debug, Clone)]
pub struct RateLimit {
    #[allow(dead_code)]
    count: u32,
    window_start: Instant,
}

impl RateLimit {
    #[allow(dead_code)]
    fn new() -> Self {
        Self {
            count: 0,
            window_start: Instant::now(),
        }
    }

    fn is_expired(&self) -> bool {
        Instant::now().duration_since(self.window_start) > WINDOW_DURATION
    }

    #[allow(dead_code)]
    fn remaining(&self, limit: u32) -> u32 {
        limit.saturating_sub(self.count)
    }

    fn reset_at(&self) -> Instant {
        self.window_start + WINDOW_DURATION
    }
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct RateLimitInfo {
    pub limit: u32,
    pub remaining: u32,
    #[allow(dead_code)]
    pub reset_at: Instant,
}

impl RateLimitInfo {
    #[allow(dead_code)]
    pub fn reset_timestamp(&self) -> u64 {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        let reset_in = self
            .reset_at
            .saturating_duration_since(Instant::now())
            .as_secs();
        now + reset_in
    }

    #[allow(dead_code)]
    pub fn to_headers(&self) -> Vec<(&'static str, String)> {
        vec![
            ("X-RateLimit-Limit", self.limit.to_string()),
            ("X-RateLimit-Remaining", self.remaining.to_string()),
            ("X-RateLimit-Reset", self.reset_timestamp().to_string()),
        ]
    }
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub enum RateLimitError {
    LimitExceeded { limit: u32, reset_at: Instant },
    InvalidToken,
}

impl std::fmt::Display for RateLimitError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RateLimitError::LimitExceeded { limit, reset_at } => {
                let reset_timestamp = reset_at
                    .duration_since(Instant::now())
                    .unwrap_or_default()
                    .as_secs();
                write!(
                    f,
                    "Rate limit exceeded: {} requests/min (resets in {} seconds)",
                    limit, reset_timestamp
                )
            }
            RateLimitError::InvalidToken => write!(f, "Invalid rate limit token"),
        }
    }
}

impl std::error::Error for RateLimitError {}

#[derive(Clone)]
pub struct RateLimiter {
    ip_limits: Arc<Mutex<HashMap<IpAddr, RateLimit>>>,
    token_limits: Arc<Mutex<HashMap<String, RateLimit>>>,
}

impl RateLimiter {
    pub fn new() -> Self {
        Self {
            ip_limits: Arc::new(Mutex::new(HashMap::new())),
            token_limits: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn check_rate_limit(
        &self,
        ip: IpAddr,
        token: Option<&str>,
    ) -> Result<RateLimitInfo, RateLimitError> {
        if let Some(token) = token {
            self.check_token_limit(token)
        } else {
            self.check_ip_limit(ip)
        }
    }

    #[allow(dead_code)]
    fn check_ip_limit(&self, ip: IpAddr) -> Result<RateLimitInfo, RateLimitError> {
        let mut limits = self.ip_limits.lock().unwrap();
        let entry = limits
            .entry(ip)
            .or_insert_with(RateLimit::new);

        if entry.window_start.elapsed() >= WINDOW_DURATION {
            entry.count = 0;
            entry.window_start = Instant::now();
        }

        if entry.count >= IP_RATE_LIMIT {
            return Err(RateLimitError::LimitExceeded {
                limit: IP_RATE_LIMIT,
                reset_at: entry.reset_at(),
            });
        }

        entry.count += 1;

        Ok(RateLimitInfo {
            limit: IP_RATE_LIMIT,
            remaining: entry.remaining(IP_RATE_LIMIT),
            reset_at: entry.reset_at(),
        })
    }

    #[allow(dead_code)]
    fn check_token_limit(&self, token: &str) -> Result<RateLimitInfo, RateLimitError> {
        let mut limits = self.token_limits.lock().unwrap();
        let entry = limits
            .entry(token.to_string())
            .or_insert_with(RateLimit::new);

        if entry.window_start.elapsed() >= WINDOW_DURATION {
            entry.count = 0;
            entry.window_start = Instant::now();
        }

        if entry.count >= TOKEN_RATE_LIMIT {
            return Err(RateLimitError::LimitExceeded {
                limit: TOKEN_RATE_LIMIT,
                reset_at: entry.reset_at(),
            });
        }

        entry.count += 1;

        Ok(RateLimitInfo {
            limit: TOKEN_RATE_LIMIT,
            remaining: entry.remaining(TOKEN_RATE_LIMIT),
            reset_at: entry.reset_at(),
        })
    }

    pub fn cleanup_expired(&self) {
        let mut ip_limits = self.ip_limits.lock().unwrap();
        ip_limits.retain(|_, limit| !limit.is_expired());

        let mut token_limits = self.token_limits.lock().unwrap();
        token_limits.retain(|_, limit| !limit.is_expired());
    }

    pub fn start_cleanup_task(&self, interval: Duration) -> tokio::task::JoinHandle<()> {
        let rate_limiter = self.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(interval);
            loop {
                interval.tick().await;
                rate_limiter.cleanup_expired();
            }
        })
    }
}

impl Default for RateLimiter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::{IpAddr, Ipv4Addr};

    #[test]
    fn test_ip_rate_limit_boundary() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));

        for i in 0..IP_RATE_LIMIT {
            let result = limiter.check_rate_limit(ip, None);
            assert!(result.is_ok(), "Request {} should succeed", i + 1);

            let info = result.unwrap();
            assert_eq!(info.limit, IP_RATE_LIMIT);
            assert_eq!(
                info.remaining,
                IP_RATE_LIMIT - (i + 1),
                "After {} requests, remaining should be {}",
                i + 1,
                IP_RATE_LIMIT - (i + 1)
            );
        }

        let result = limiter.check_rate_limit(ip, None);
        assert!(result.is_err(), "Request 101 should fail");

        match result {
            Err(RateLimitError::LimitExceeded { limit, .. }) => {
                assert_eq!(limit, IP_RATE_LIMIT);
            }
            _ => panic!("Expected LimitExceeded error"),
        }
    }

    #[test]
    fn test_token_rate_limit_boundary() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        let token = "test-token";

        for i in 0..TOKEN_RATE_LIMIT {
            let result = limiter.check_rate_limit(ip, Some(token));
            assert!(result.is_ok(), "Request {} should succeed", i + 1);

            let info = result.unwrap();
            assert_eq!(info.limit, TOKEN_RATE_LIMIT);
            assert_eq!(
                info.remaining,
                TOKEN_RATE_LIMIT - (i + 1),
                "After {} requests, remaining should be {}",
                i + 1,
                TOKEN_RATE_LIMIT - (i + 1)
            );
        }

        let result = limiter.check_rate_limit(ip, Some(token));
        assert!(result.is_err(), "Request 1001 should fail");

        match result {
            Err(RateLimitError::LimitExceeded { limit, .. }) => {
                assert_eq!(limit, TOKEN_RATE_LIMIT);
            }
            _ => panic!("Expected LimitExceeded error"),
        }
    }

    #[test]
    fn test_different_ips() {
        let limiter = RateLimiter::new();
        let ip1 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        let ip2 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 2));

        for _ in 0..IP_RATE_LIMIT {
            limiter.check_rate_limit(ip1, None).unwrap();
        }

        let result = limiter.check_rate_limit(ip1, None);
        assert!(result.is_err(), "IP1 should be rate limited");

        let result = limiter.check_rate_limit(ip2, None);
        assert!(result.is_ok(), "IP2 should have separate limit");
    }

    #[test]
    fn test_window_reset() {
        let limiter = RateLimiter::new();
        let ip = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));

        for _ in 0..10 {
            limiter.check_rate_limit(ip, None).unwrap();
        }

        {
            let mut limits = limiter.ip_limits.lock().unwrap();
            let entry = limits.get_mut(&ip).unwrap();
            entry.window_start = Instant::now() - Duration::from_secs(61);
        }

        let result = limiter.check_rate_limit(ip, None).unwrap();
        assert_eq!(
            result.remaining,
            IP_RATE_LIMIT - 1,
            "After window reset, counter should reset and remaining should be limit - 1"
        );
    }

    #[test]
    fn test_cleanup_expired() {
        let limiter = RateLimiter::new();
        let ip1 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1));
        let ip2 = IpAddr::V4(Ipv4Addr::new(127, 0, 0, 2));

        limiter.check_rate_limit(ip1, None).unwrap();
        limiter.check_rate_limit(ip2, None).unwrap();

        assert_eq!(limiter.ip_limits.lock().unwrap().len(), 2);

        {
            let mut limits = limiter.ip_limits.lock().unwrap();
            limits.get_mut(&ip1).unwrap().window_start = Instant::now() - Duration::from_secs(61);
        }

        limiter.cleanup_expired();

        assert_eq!(
            limiter.ip_limits.lock().unwrap().len(),
            1,
            "Expired entry should be removed"
        );
        assert!(
            limiter.ip_limits.lock().unwrap().contains_key(&ip2),
            "Non-expired entry should remain"
        );
    }
}
