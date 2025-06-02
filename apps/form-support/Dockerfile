# apps/form-support/Dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install && npm run build
EXPOSE 3002
CMD ["npm", "run", "dev"]