# healthcheck-monitoring

A monitoring project consisting of a simple elm cockpit and a java backend.

The frontend retrieves healthcheck data from the backend, parses it and displays the results for healthchecks of the following format
```json
{
    "outcome": "UP",
    "checks": [
        {
            "name": "IncorrectTasks",
            "state": "UP",
            "data": {
                "noCurrentWorker": 2,
                "noInboxAssigned": 5
            }
        },
        {
            "name": "RoutingModel",
            "state": "UP",
            "data": {
              "modelValidFrom": "2000-01-01T06:00:00",
              "modelId": 42,
              "modelStatus": "OK",
              "routing-active": true
            }
        },
        {
            "name": "TaskQueue",
            "state": "UP",
            "data": {
                "itemCount": 0
            }
        }
    ]
}
```

The backend polls several healthchecks and saved the response as it is.
