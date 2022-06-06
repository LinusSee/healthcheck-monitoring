import express from 'express';
import cors from 'cors'
import { tasksHealthcheckId, healthchecksBasedata, healthcheckData, nextTaskHealthcheckData } from './data/basedata.js'


const app = express();
app.use(cors());
const port = 3000;



// Endpoints
// /api/v1/healthchecks             BaseData for all existing healthchecks
// /api/v1/healthchecks/{id}        BaseData such as name, url etc.
// /api/v1/healthchecks/{id}/data   Returns all healthcheck results polled for this id (later on maybe dates as query params)

app.get('/mock-monitoring-backend/api/v1/healthchecks', (req, res) => {
  res.send(healthchecksBasedata);
});


app.get('/mock-monitoring-backend/api/v1/healthchecks/:healthcheckId/data', (req, res) => {
  const healthcheckId = req.params.healthcheckId;
  const result = healthcheckData[healthcheckId];

  result
    ? res.send(result)
    : res.sendStatus(404);
});



// Start app
app.listen(port, () => {
  console.log(`App is started and listening to port ${port}`)
});

function updateTaskHealthcheckData() {
  const nextData = nextTaskHealthcheckData();
  healthcheckData[tasksHealthcheckId].healthcheckResponse.push(nextData);
}
setInterval(updateTaskHealthcheckData, 20000);
