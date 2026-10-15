var express = require('express'),
    { Pool } = require('pg'),
    cookieParser = require('cookie-parser'),
    path = require('path'),
    app = express(),
    server = require('http').Server(app),
    io = require('socket.io')(server, { path: '/result/socket.io' });

var port = process.env.PORT || 4000;

// Create two namespaces: root ("/") and "/result"
var rootNamespace = io.of('/');      // Default namespace for pages at "/"
var resultNamespace = io.of('/result'); // Namespace for pages at "/result"

// Handle connections on the default namespace
rootNamespace.on('connection', function (socket) {
  console.log("Connected on root namespace");
  socket.emit('message', { text: 'Welcome from root!' });

  socket.on('subscribe', function (data) {
    socket.join(data.channel);
  });
});

// Handle connections on the /result namespace
resultNamespace.on('connection', function (socket) {
  console.log("Connected on /result namespace");
  socket.emit('message', { text: 'Welcome from result!' });

  socket.on('subscribe', function (data) {
    socket.join(data.channel);
  });
});

// --- PostgreSQL logic with automatic retry ---
var pgHost = process.env.PG_HOST || 'db';
var pgPort = Number(process.env.PG_PORT || 5432);
var pgUser = process.env.PG_USER || 'postgres';
var pgPassword = process.env.PG_PASSWORD || 'postgres';
var pgDatabase = process.env.PG_DATABASE || 'postgres';

var pool = new Pool({
  host: pgHost,
  port: pgPort,
  user: pgUser,
  password: pgPassword,
  database: pgDatabase,

  // Return control to the retry loop if the DB cannot be reached.
  connectionTimeoutMillis: 5000
});

// Handle unexpected errors on idle pooled connections.
pool.on('error', function (err) {
  console.error('Unexpected PostgreSQL connection error:', err.message);
});

async function getVotes() {
  try {
    // Acquire and release a connection for each query.
    // The pool can replace connections that fail after a database failover.
    var result = await pool.query(
      'SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote'
    );

    var votes = collectVotesFromResult(result);

    // Broadcast to both namespaces.
    rootNamespace.emit('scores', JSON.stringify(votes));
    resultNamespace.emit('scores', JSON.stringify(votes));
  } catch (err) {
    console.error(
      'Database query failed; will retry:',
      err.message
    );
  } finally {
    // Always try again, whether the query succeeded or failed.
    setTimeout(getVotes, 1000);
  }
}

function collectVotesFromResult(result) {
  var votes = { a: 0, b: 0 };

  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count, 10);
  });

  return votes;
}

// Start polling immediately. The web server can start even if DB is down.
getVotes();
// --- End DB logic ---

// Basic middleware
app.use(cookieParser());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the "views" folder on both "/" and "/result"
app.use(express.static(path.join(__dirname, 'views')));
app.use("/result", express.static(path.join(__dirname, 'views')));

// Serve the same index.html for both routes
app.get(['/', '/result'], function (req, res) {
  res.sendFile(path.resolve(__dirname, 'views', 'index.html'));
});

// Start server
server.listen(port, function () {
  console.log('App running on port ' + server.address().port);
});
