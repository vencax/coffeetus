# coffeetus


[![build status](https://travis-ci.org/vencax/coffeetus.svg)](https://travis-ci.org/vencax/coffeetus)


[TUS Protocol 1.0.0](http://www.tus.io/protocols/resumable-upload.html) Server Implementation


## Configuration

through few environment variables:

- PORT: port on this server will sit (default: 1080)
- FILESDIR: path to folder where the files will land (default: 'files' folder within this project)
- DATABASE_URL: [sequelize](http://sequelizejs.com/) connection string for storing info about particular uploads.
- TUS_MAX_SIZE_IN_MEGAS: (optional) max file size in megabytes


## Install
```
npm install coffeetus
```

## Run

```
export DATABASE_URL=xxxxxxxxxx
node server.js
```

## Tools

### brewtus2coffeetus

Brewtus stored metadata about particular upload along actual uploaded file.
They end with json suffix and contain JSON serialized metadata.
brewtus2coffeetus finds them, parses, and create according DB record.

```
export FILESDIR=/data/brewtus
export DATABASE_URL=sqlite://db.sqlite
coffee tools/brewtus2coffeetus.coffee
# optionaly you can remove all the info file, since they are no longer needed
# find $FILESDIR -name "*.json" | xargs rm
```

## License

The MIT License (MIT)

Copyright (c) 2015 Vaclav Klecanda

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
