const { dbQuery } = require('./src/db');

async function run() {
  console.log('Querying all logs in database:');
  try {
    const logs = await dbQuery.all('SELECT * FROM logs');
    console.log(logs);
  } catch (err) {
    console.error(err);
  }
  process.exit(0);
}
run();
