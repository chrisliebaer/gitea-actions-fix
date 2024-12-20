const { execSync } = require("child_process");
const out = execSync(__dirname + "/post.sh", { encoding: 'utf-8' });
console.log(out);
