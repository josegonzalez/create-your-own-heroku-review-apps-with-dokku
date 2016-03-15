# Create your own heroku review apps with dokku

[Heroku](https://www.heroku.com/) has amazing feature [Review Apps](https://devcenter.heroku.com/articles/github-integration-review-apps)

In short, you can deploy your git brunches as standalone apps with unique urls.
This is very useful feature.

And as I don't use Heroku, I'll show you
how to create your own Heroku review apps on [dokku](https://github.com/dokku/dokku).

# Preinstall steps

You need to create public - `id_dokku_rsa.pub` and private - `id_dokku_rsa` keys for deployment,
generate them with `ssh-keygen -t rsa` command.

You need to have some domain i.e. `mysite.com` and access to `dns` `CNAME-records`.

Add two records

```bash
dokku.mysite.com     300     IN      CNAME   YOUR_UBUNTU_SERVER_IP
*.dokku.mysite.com    300     IN      CNAME   YOUR_UBUNTU_SERVER_IP
```

(_you always can use your `/etc/hosts` file if you have no access to cname-records_)

And you need a clean ubuntu 14.04 server.

# Install steps

### Install dokku

ssh into your ubuntu server and run there

```bash
wget https://raw.githubusercontent.com/dokku/dokku/v0.4.14/bootstrap.sh
sudo DOKKU_TAG=v0.4.14 bash bootstrap.sh
```

then goto in browser to `YOUR_UBUNTU_SERVER_IP` and
enter in the web interface VHOST=mysite.com and public `id_dokku_rsa.pub` key
generated at `Preinstall steps`.

### Fix installation errors

With some probability you can get one dokku installation problem,
to check it, you need to look into `/home/dokku/.ssh/authorized_keys` file.

Just run `cat /home/dokku/.ssh/authorized_keys` and if you will see there
garbage like this

```
command="echo 'Please login as the user \"ubuntu\" rather than the user \"root\".';echo;sleep 10"
``` 

in `/home/dokku/.ssh/authorized_keys` just remove that garbage. 

Resulted `authorized_keys` must be looking like this

```bash
command="FINGERPRINT=42:ed:bd:8a:1e:aa:60:4f:8b:62:a1:5e:da:b6:53:b0 NAME=admin `cat /home/dokku/.sshcommand` $SSH_ORIGINAL_COMMAND",no-agent-forwarding,no-user-rc,no-X11-forwarding,no-port-forwarding YOUR_KEY
```

where YOUR_KEY is your `id_dokku_rsa.pub` key content.

### Hack dokku

Then you need to hack `dokku` a little.

The problem is that `stable dokku` version contains one error,
which prevents you to deploy any other branches than master.

I fixed this error in this [PR](https://github.com/dokku/dokku/pull/1993)
but it is not in stable dokku version.

You need to find in `/var/lib/dokku/plugins/enabled/git/commands` file following line

```
if test -f "$PLUGIN_PATH"/enabled/*/receive-branch; then
```

and replace this line with

```
if [[ $(find "$PLUGIN_PATH"/enabled/*/receive-branch 2>/dev/null | wc -l) != 0 ]]; then
```

### Install dokku plugin which allows you to deploy non master brunches

To support multiple brunches in dokku,
I wrote a simple dokku plugin [dokku-receive-branch](https://github.com/cinarra/dokku-receive-branch.git) (don't forget to star it ;-))

To install plugin run

```bash
sudo dokku plugin:install https://github.com/cinarra/dokku-receive-branch.git
```

And as plugin in alpha quality stage, don't forget to update it periodically.

```bash
sudo dokku plugin:update receive-branch
```

### Setup nginx

To prevent nginx respond on unkown hosts run command below

```bash
printf "server {\n  return 404;\n}\n" | sudo tee __default__.conf > /dev/null
sudo service nginx reload
```

This command adds

```bash
server {
  return 404;
}
```

to nginx config, so any requests to unknow hosts or via IP will be rejected with 404 error.


### Create dokku app

```bash
dokku apps:create dokku
```


# Prepare your project for deployment

You need to create `Dockerfile` file in the root of your project,
for node apps it's content is

[Dockerfile](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/Dockerfile)

Project install and run file `run.sh`,

[run.sh](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/run.sh)

*As pnpm sometimes crashes on install, I use a simple
[pnpm retry hack](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/run.sh#L14-L24)*

*pnpm is 20x faster than npm install so I recommend it to you*

And you need to add a `CHECKS` file,

[CHECKS](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/CHECKS)

More information about `CHECKS` file you can read in [dokku documentation](http://dokku.viewdocs.io/dokku/checks-examples/)

In current project I just check that runned container will respond with some html which contains `kotatsu` string.

```bash
/  kotatsu
```

Also add following two scripts in package json section, or create a bash aliases.

[deploy](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/package.json#L9)

```bash
"deploy": "git push dokku $(git rev-parse --abbrev-ref HEAD)"
```

[destroy](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/package.json#L10)

```bash
"destroy": "git push dokku $(git rev-parse --abbrev-ref HEAD)"
```

Installation complete.

---

# User install

### ssh setup

Now all your team members should add private `id_dokku_rsa` key to their computers.

Get `id_dokku_rsa` key generated at `Preinstall steps` and place it inside your `~/.ssh` folder.

Add to `~/.ssh/config` (if not exists create it) next lines

```bash
Host dokku.mysite.com
  User dokku
  IdentityFile ~/.ssh/id_dokku_rsa
```

### git setup

Add additional remote endpoint to git

```bash
git remote add dokku dokku@dokku.mysite.com:dokku
```

User install complete

---

Now you can easily deploy any branch of you project on the server

# Deploy

*Always create initial deploy on master, because of internal realization details*

You can deploy any branch you want, just run

```bash
npm run deploy
# this is a shortcut to
# git push dokku ${CURRENT_GIT_BRANCH_NAME}
# where CURRENT_GIT_BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
```

To deploy squashed commits run

```bash
npm run deploy -- --force
```

Master brunch will be available at `http://dokku.mysite.com`
and all other brunches will be available
at `${CURRENT_GIT_BRANCH_NAME}.dokku.mysite.com`

After you have merged your branch, branch app is not needed,
so inside your brunch run to free system resources.

```bash
npm run destroy
# this is a shortcut to
# git push dokku --delete ${CURRENT_GIT_BRANCH_NAME}
# where CURRENT_GIT_BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
```

*This operation is not permitted on master branch, if you are really sure that you want to destroy master
do this manually at server*

```bash
dokku apps:destroy dokku force
```

# The end
