#!/usr/bin/env node

const path = require('path')
const shell = require('shelljs')
const directory = path.join(__dirname, '..')
const semver = require('semver')

const nodeVersion = shell.exec('node -v', { silent: true }).stdout.replace(/[^0-9\.]/g,"")
const rubyVersion = shell.exec('ruby -v', { silent: true }).stdout.replace(/[^0-9\.]/g,"").substring(0,5)
const railsVersion = shell.exec('rails -v', { silent: true }).stdout.replace(/[^0-9\.]/g,"")

console.log('Node: ', nodeVersion)
console.log('Ruby: ', rubyVersion)
console.log('Rails: ', railsVersion)


if (!semver.gte(nodeVersion, '18.0.0')) {
  console.log('Please upgrade Node to version 18.0.0 or higher to continue')
  process.exit()
}

if (!semver.gte(rubyVersion, '3.0.0')) {
  console.log('Please upgrade Ruby to version 3.0.0 or higher to continue')
  process.exit()
}

if (!semver.gte(railsVersion, '7.0.0')) {
  console.log('Please upgrade Rails to version 7.0.0 or higher to continue')
  process.exit()
}

const cmds = [
  {
    shellCmd: 'exec',
    args: `bin/rails app:template LOCATION=${directory}/groovestack-rails-template.rb`
  }
]

cmds.forEach((cmd) => {
  console.log(cmd)
  shell[cmd.shellCmd](cmd.args)
})