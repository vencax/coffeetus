# brewtus

[TUS Protocol 0.2.1](http://www.tus.io/protocols/resumable-upload.html) Server Implementation


## Configuration

throught few environment variables:

- PORT: port on this server will sit (default: 1080)
- FILESDIR: path to folder where the files will land (default: 'files' folder within this project)
- SERVERSTRING: content of "server" header sent back to clients (default: 'BrewTUS/0.1')


edit brewtus.json
```js
{
	"host": "192.168.1.117",
	"port": 8080,
	"server": "BrewTUS/0.1",
	"files": "files",
	"logDir": "logs",
	"logRotateSize": 10485760,
	"logLevel": "info"
}
```

## Install
```
npm install
```

## Run

```
node server.js
```

## Test/Try out

Browser (Tested with Chrome 27/Firefox 21/IE 10/Safari 6)
```
http://127.0.0.1:8080/
```

or

Command line
Get [tuspy](https://github.com/vayam/tuspy) client
```
python tuspy.py -f <file>
```

## License
[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
