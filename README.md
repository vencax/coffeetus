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
