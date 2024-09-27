# create-groovestack
create-groovestack is a utility that allows you to quickly bootstrap a new [Groovestack](https://talysto.com/tech/groovestack/) application. It is powered by [Groovestack CORE](https://github.com/talysto/groovestack-core) modules
* Base
* Config
* Auth 
* Jobs 

Please reference the Groovestack CORE [Documentation](https://github.com/talysto/groovestack-core) for module descriptions and configuration options.

## Getting Started

### spin up a ruby container
```
docker compose run --rm -it -v `pwd`\:/usr/dev -p 3000\:3000 -p 3036\:3036 --build api /bin/sh
```

### run the template
```
yarn global add https://github.com/mgamba/gsd && create-groovestack myapp
cd myapp
```

### start the servers
```
./bin/dev
```

