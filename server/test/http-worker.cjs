const { startServer } = require('../index');
startServer().then(server => {
  if (!server) process.exit(1);
  const ready = () => process.send({ port: server.address().port });
  if (server.listening) ready(); else server.once('listening', ready);
});
