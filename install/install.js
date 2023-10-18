#!/usr/bin/env node

const path = require('path')
const shell = require('shelljs')
const directory = path.join(__dirname, '..')
const app_location = process.env.PWD

shell.exec(`${__dirname}/groovestack-install.sh ${process.argv[2]} ${directory} ${app_location}`)