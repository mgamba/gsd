#!/usr/bin/env node

const path = require('path')
const shell = require('shelljs')
const directory = path.join(__dirname, '..')

shell.exec(`${__dirname}/groovestack-install.sh ${process.argv[2]} ${directory}`)