# User install

## ssh setup

Download `id_dokku_rsa` key and place it inside your `~/.ssh` folder.

Add to `~/.ssh/config` (if not exists create it) next lines

```bash
Host dokku.mysite.com
  User dokku
  IdentityFile ~/.ssh/id_dokku_rsa
```

## git setup

Clone current repositary and `cd` into it, run

```bash
git remote add dokku dokku@dokku.mysite.com:dokku
```

# Usage

Create branch as usual *write your own brunch name instead of my-branch-name*

```bash
git checkout -b my-branch-name
```

change README.md for example

```bash
echo 1 >> README.md
git add README
git commit -m "My great change"
```

And run

```bash
npm run deploy
```

Now after deployment process ends you could see you changes at `my-branch-name.dokku.mysite.com`

After commit squashing or/and history rewrites you should run

```bash
npm run deploy -- --force
```

To destroy app on the server just run inside branch

```bash
npm run destroy
```

*This operation is not permitted on master branch, if you are really sure that you want to destroy master
do this manually at server*

```bash
dokku apps:destroy dokku force
```
