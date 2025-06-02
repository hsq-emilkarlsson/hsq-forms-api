# apps/form-feedback/Dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install && npm run build
EXPOSE 3001
CMD ["npm", "run", "dev"]