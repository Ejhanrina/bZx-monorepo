FROM node:16.8.0-alpine3.13

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json /usr/src/app/
RUN npm install --production

# Bundle app source
COPY . /usr/src/app

RUN npm run build
EXPOSE 8081

CMD [ "npm", "start" ]