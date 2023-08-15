# FROM node
# FROM --platform=linux/amd64 node:11.15
# FROM node:10.16-alpine
FROM --platform=linux/amd64 node
ADD mern-todo-main /mern-todo-main/


WORKDIR /mern-todo-main/client
RUN npm install

WORKDIR /mern-todo-main/
RUN npm install 

RUN npm run dev

# Stage 2: Serve the React app using Nginx
FROM --platform=linux/amd64 nginx:1.21
COPY --from=build /app/build /usr/share/nginx/html
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]

