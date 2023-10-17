#!/usr/bin/env node

const shell = require('shelljs')
const directory = process.env.PWD

shell.exec(`${__dirname}/groovestack-new.sh ${process.argv[2]} ${directory}`)