// todo: figure out why stdio: 'inherit' doesn't work
const { execSync } = require("child_process");
const out = execSync(__dirname + "/main.sh", { encoding: 'utf-8' });
console.log(out);
