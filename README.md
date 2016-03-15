# User install

Read [DEPLOY.md](DEPLOY.md)

# Install dokku (for system administrators)

## On the server

Ubuntu 14.04!!!

After [this dokku install](http://dokku.viewdocs.io/dokku/installation/) instructions

```bash
wget https://raw.githubusercontent.com/dokku/dokku/v0.4.14/bootstrap.sh
sudo DOKKU_TAG=v0.4.14 bash bootstrap.sh
# goto hostanme, enter VHOST and ssh-key
```
I got following problem:

garbage like this `command="echo 'Please login as the user \"ubuntu\" rather than the user \"root\".';echo;sleep 10"` in `/home/dokku/.ssh/authorized_keys`

So manually I removed it and file must be looking like this:

```bash
command="FINGERPRINT=42:ed:bd:8a:1e:aa:60:4f:8b:62:a1:5e:da:b6:53:b0 NAME=admin `cat /home/dokku/.sshcommand` $SSH_ORIGINAL_COMMAND",no-agent-forwarding,no-user-rc,no-X11-forwarding,no-port-forwarding YOUR_KEY
```

Then, you need to find in `/var/lib/dokku/plugins/enabled/git/commands`
next line

```
if test -f "$PLUGIN_PATH"/enabled/*/receive-branch; then
```

and replace with

```
if [[ $(find "$PLUGIN_PATH"/enabled/*/receive-branch 2>/dev/null | wc -l) != 0 ]]; then
```

(*this my PR https://github.com/dokku/dokku/pull/1993*)

Generated rsa key for dokku - `id_dokku_rsa`, and replace `YOUR_KEY` in `/home/dokku/.ssh/authorized_keys` with public key part

Install plugin to allow deploy multiple branches on dokku

```bash
sudo dokku plugin:install https://github.com/cinarra/dokku-receive-branch.git
```

Update plugin

```bash
sudo dokku plugin:update receive-branch
```

Prevent nginx to respond on unkown hosts

```bash
printf "server {\n  return 404;\n}\n" | sudo tee __default__.conf > /dev/null
sudo service nginx reload
```

## Locally

Added to `~/.ssh/config` (if not exists create it)

```bash
Host dokku.mysite.com
  User dokku
  IdentityFile ~/.ssh/id_dokku_rsa
```

# Prepare project for deployment

[Dockerfile](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/Dockerfile)

Container will not be deployed until this checks done

[CHECKS](https://github.com/istarkov/create-your-own-heroku-review-apps-with-dokku/blob/master/CHECKS)


# Create app on server

```bash
dokku apps:create dokku
```

# Git setup

```bash
git remote add dokku dokku@dokku.mysite.com:dokku
```

# Deploy

*Always create initial deploy on master, because of internal realization details*

You can deploy any branch you want, just run

```bash
npm run deploy
# this is a shortcut to command
# git push dokku ${CURRENT_GIT_BRANCH_NAME}
# where CURRENT_GIT_BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
```

To deploy squashed commits run

```bash
npm run deploy -- --force
```

Master brunch will be available at `http://dokku.mysite.com` and all other brunches will be available
at `${brunch_name}.dokku.mysite.com`

After you merged your branch, branch app is not needed, so inside your brunch run to free system resources

```bash
npm run destroy
# this is a shortcut to command
# git push dokku --delete ${CURRENT_GIT_BRANCH_NAME}
# where CURRENT_GIT_BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
```

*This operation is not permitted on master branch, if you are really sure that you want to destroy master
do this manually at server*

```bash
dokku apps:destroy dokku force
```



# Miscellaneous

How to install mosh and tmux

```
sudo add-apt-repository ppa:keithw/mosh
sudo apt-get update
sudo apt-get install mosh
sudo apt-get install tmux
```
