## How to configure new containers to send logs to Datadog.
Configure these ENV variables through task definitions: 
```
{ "name": "DD_AGENT_HOST", "value": "172.17.0.1" },
{ "name": "DD_TRACE_AGENT_PORT", "value": "8126" },
{ "name": "DD_SERVICE", "value": "your-service-name" },
{ "name": "DD_ENV", "value": "production" },
{ "name": "DD_VERSION", "value": "1.0.0" },
```