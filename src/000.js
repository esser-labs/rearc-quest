const fs = require('fs')
const https = require('https')
const express = require('express')
const app = express()
const port = 3000

const httpsOptions = {
    key: fs.readFileSync(`${__dirname}/ssl/cert.key`),
    cert: fs.readFileSync(`${__dirname}/ssl/cert.pem`)
}

app.get('/', function (req, res) {
const { exec } = require('child_process');
exec('bin/001', (err, stdout, stderr) => {
  if (err) {
    return res.send(`${stderr}`);
  }
  return res.send(`${stdout}`);
});
});

app.get('/aws', function (req,res) {
const { exec } = require('child_process');
exec('bin/002', (err, stdout, stderr) => {
  return res.send(`${stdout}`);
});
});

app.get('/docker', function (req,res) {
const { exec } = require('child_process');
exec('bin/003', (err, stdout, stderr) => {
  return res.send(`${stdout}`);
});
});

app.get('/loadbalanced', function (req,res) {
const { exec } = require('child_process');
exec('bin/004 ' + JSON.stringify(req.headers), (err, stdout, stderr) => {
  return res.send(`${stdout}`);
});
});

app.get('/tls', function (req,res) {
const { exec } = require('child_process');
exec('bin/005 ' + JSON.stringify(req.headers), (err, stdout, stderr) => {
  return res.send(`${stdout}`);
});
});

app.get('/secret_word', function (req,res) {
const { exec } = require('child_process');
exec('bin/006 ' + JSON.stringify(req.headers), (err, stdout, stderr) => {
  return res.send(`${stdout}`);
});
});

if (process.env.USE_SSL === 'true') {
  const server = https.createServer(httpsOptions, app)
  server.listen(port, () => console.log(`Rearc quest listening on port ${port}!`))
} else {
  app.listen(port, () => console.log(`Rearc quest listening on port ${port}!`))
}

