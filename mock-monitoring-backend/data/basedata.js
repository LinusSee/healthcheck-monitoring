const routingModelHealthcheckId = 'ba32561f-22d9-4c86-82fc-d471d05d7be1';
const tasksHealthcheckId = '355c722a-4f1c-42fb-a9a3-4fb11f5a0508';

const healthchecksBasedata =
  { 'healthcheckBasedata': [{ 'id': routingModelHealthcheckId
                            , 'name': 'Routing Model'
                            , 'url': 'http://localhost:3001/routingmodel/api/health/application'
                            , 'chartConfigs': []
                            //, probably config data like which params to use and how to display it
                            },
                            { 'id': tasksHealthcheckId
                            , 'name': 'Tasks'
                            , 'url': 'http://localhost:3002/tasks/api/health/application'
                            , 'chartConfigs': [ { 'healthcheckName': 'TaskQueue'
                                                , 'fieldname': 'itemCount'
                                                }
                                              , { 'healthcheckName': 'IncorrectTasks'
                                                , 'fieldname': 'noCurrentWorker'
                                                }
                                              ]
                            //, probably config data like which params to use and how to display it
                            }]
  };

function nextTaskHealthcheckData() {
  const noCurrentWorker = Math.floor(Math.random() * 20);
  const noInboxAssigned = Math.floor(Math.random() * 15);
  const itemCount = Math.floor(Math.random() * 10);

  const nextData =
              {
                "outcome": "UP",
                "checks": [
                    {
                        "name": "IncorrectTasks",
                        "state": "UP",
                        "data": {
                            "noCurrentWorker": noCurrentWorker,
                            "noInboxAssigned": noInboxAssigned
                        }
                    },
                    {
                        "name": "TaskQueue",
                        "state": "UP",
                        "data": {
                            "itemCount": itemCount,
                            "boolField": true
                        }
                    }
                ]
              };

    return nextData;
}
const tasksHealthcheckData =
  { 'healthcheckResponse': [
                {
                  "outcome": "UP",
                  "checks": [
                      {
                          "name": "IncorrectTasks",
                          "state": "UP",
                          "data": {
                              "noCurrentWorker": 1,
                              "noInboxAssigned": 2
                          }
                      },
                      {
                          "name": "TaskQueue",
                          "state": "UP",
                          "data": {
                              "itemCount": 4,
                              "boolField": true
                          }
                      }
                  ]
                },
                {
                  "outcome": "UP",
                  "checks": [
                      {
                          "name": "IncorrectTasks",
                          "state": "UP",
                          "data": {
                              "noCurrentWorker": 4,
                              "noInboxAssigned": 7
                          }
                      },
                      {
                          "name": "TaskQueue",
                          "state": "UP",
                          "data": {
                              "itemCount": 20
                          }
                      }
                  ]
                },
                {
                  "outcome": "DOWN",
                  "checks": [
                      {
                          "name": "IncorrectTasks",
                          "state": "DOWN",
                          "data": {
                              "noCurrentWorker": 11,
                              "noInboxAssigned": 20
                          }
                      },
                      {
                          "name": "TaskQueue",
                          "state": "UP",
                          "data": {
                              "itemCount": 5,
                              "boolField": true
                          }
                      }
                  ]
                },
                {
                  "outcome": "UP",
                  "checks": [
                      {
                          "name": "IncorrectTasks",
                          "state": "UP",
                          "data": {
                              "noCurrentWorker": 3,
                              "noInboxAssigned": 1
                          }
                      },
                      {
                          "name": "TaskQueue",
                          "state": "UP",
                          "data": {
                              "itemCount": 4,
                              "boolField": true
                          }
                      }
                  ]
                },
                {
                  "outcome": "UP",
                  "checks": [
                      {
                          "name": "IncorrectTasks",
                          "state": "UP",
                          "data": {
                              "noCurrentWorker": 9,
                              "noInboxAssigned": 2
                          }
                      },
                      {
                          "name": "TaskQueue",
                          "state": "UP",
                          "data": {
                              "itemCount": 2,
                              "boolField": false
                          }
                      }
                  ]
                }
            ]
  };


const healthcheckData = {};
healthcheckData[tasksHealthcheckId] = tasksHealthcheckData


export { tasksHealthcheckId, healthchecksBasedata, healthcheckData, nextTaskHealthcheckData };
