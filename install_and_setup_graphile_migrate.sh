#https://nodejs.org/en/download/package-manager


# installs nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# reiniciar consola, fechar e abrir

# download and install Node.js (you may need to restart the terminal)
nvm install 22

# verifies the right Node.js version is in the environment
node -v # should print `v22.11.0`

# verifies the right npm version is in the environment
npm -v # should print `10.9.0`


corepack enable

# eliminar ficheiro
rm yarn.lock 

# installa os packages que estao em package.json
yarn install


# rename .env.dist para .env



yarn run graphile-migrate reset --erase

ou

yarn gm reset --erase


yarn gm watch

/home/carva014/Work/Code/FAO/ISO28258/iso28258-public-master/migrations/current.sql



yarn gm commit 
