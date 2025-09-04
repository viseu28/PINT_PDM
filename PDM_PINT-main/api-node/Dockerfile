# Use Node.js 18 LTS
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps --only=production

# Copy application code
COPY . .

# Create uploads directory
RUN mkdir -p public/uploads

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "index.js"]
