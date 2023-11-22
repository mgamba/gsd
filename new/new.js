#!/usr/bin/env node
const path = require("path");
const shell = require("shelljs");
const semver = require("semver");

const directory = path.join(__dirname, "..");
const { argv } = require("process");

let pkg_manager = process.env.npm_execpath.includes('yarn') 
  ? 'yarn' 
  : process.env.npm_execpath.includes('pnpm') 
    ? 'pnpm'
    : 'npm' // default to npm

if (!argv[2]) {
  argv[2] = "GroovestackDemoApp";
}

const nodeVersion = shell
  .exec("node -v", { silent: true })
  .stdout.replace(/[^0-9\.]/g, "");
const rubyVersion = shell
  .exec("ruby -v", { silent: true })
  .stdout.replace(/[^0-9\.]/g, "")
  .substring(0, 5);
const railsVersion = shell
  .exec("rails -v", { silent: true })
  .stdout.replace(/[^0-9\.]/g, "");

console.log("Node: ", nodeVersion);
console.log("Ruby: ", rubyVersion);
console.log("Rails: ", railsVersion);

let cmds = [
  {
    shellCmd: "exec",
    args: `rails new ${argv[2]} -d postgresql --skip-turbolinks --skip-hotwire --skip-jbuilder --skip-webpack-install --skip-bootsnap`,
  },
  {
    shellCmd: "cd",
    args: argv[2],
  },
  {
    shellCmd: "exec",
    args: 'bundle lock --add-platform x86_64-linux',
  },
  {
    shellCmd: "exec",
    args: 'bundle lock --add-platform=aarch64-linux',
  },
  {
    shellCmd: "exec",
    args: `PKG_MNG=${pkg_manager} bin/rails app:template LOCATION=${directory}/groovestack-rails-template.rb`,
  },
  // {
  //   shellCmd: "exec",
  //   args: `rubocop -x`,
  // },
  // {
  //   shellCmd: "exec",
  //   args: `npx prettier . --write`,
  // },
];

if (!semver.gte(nodeVersion, "18.0.0")) {
  console.log("Please upgrade Node to version 18.0.0 or higher to continue.");

  console.log(
    "If not installed already, we recommend using ASDF to manage your Node versions."
  );
  console.log("Here's a quick guide on how to install ASDF and Node 18.0.0+");
  console.log("See section 'Install a plugin'");
  console.log("https://asdf-vm.com/guide/getting-started.html");

  process.exit();
}

if (!semver.gte(rubyVersion, "3.1.0")) {
  console.log("Please upgrade Ruby to version 3.1.0 or higher to continue.");

  console.log(
    "If not already installed, we recommend using ASDF to manage your Ruby versions."
  );
  console.log("Here's a quick guide on how to install ASDF and Ruby 3.1.0+");
  console.log("https://mac.install.guide/rubyonrails/7.html");

  process.exit();
}

if (!semver.satisfies(railsVersion, ">=7.0.0 || <7.1.0")) {
  console.log(
    "Groovestack requires Rails 7+ to install successfully. We will attempt to add the correct version of Rails for you."
  );

  cmds.unshift({
    shellCmd: "exec",
    args: `if ! gem list rails -i --silent; then echo "Installing rails..."; gem install rails -v 7.0.8; fi;`,
  });
}

cmds.forEach((cmd) => {
  console.log(cmd);
  shell[cmd.shellCmd](cmd.args);
});
