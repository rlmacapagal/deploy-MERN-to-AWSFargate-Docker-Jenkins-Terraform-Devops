# FROM node
# FROM --platform=linux/amd64 node:11.15
# FROM node:10.16-alpine
FROM --platform=linux/amd64 node
ADD mern-todo-main /mern-todo-main/


WORKDIR /mern-todo-main/client
RUN npm install

WORKDIR /mern-todo-main/
RUN npm install 

CMD npm run dev
