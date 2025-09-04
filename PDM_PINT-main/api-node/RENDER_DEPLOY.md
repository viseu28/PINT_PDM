# PINT PDM API - Render Deploy

## Environment Variables for Render

Set these in your Render service environment variables:

### Database Configuration
```
DATABASE_URL=postgresql://username:password@hostname:port/database_name
DB_HOST=your-postgres-host
DB_USER=your-postgres-user
DB_PASSWORD=your-postgres-password
DB_NAME=pint
DB_PORT=5432
```

### Application Configuration
```
NODE_ENV=production
PORT=3000
JWT_SECRET=your-jwt-secret-key
```

### Cloudinary Configuration (from .env)
```
CLOUDINARY_CLOUD_NAME=de3xeyh4u
CLOUDINARY_API_KEY=819929135217463
CLOUDINARY_API_SECRET=XvpF8HgE8S3zSrObksS0hvHNGoc
```

### Email Configuration (from .env)
```
EMAIL_USER=softskillsnotifier@gmail.com
EMAIL_PASS=nqqgdzhdbtmhzcsr
```

### Firebase Configuration
```
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email
```

## Deploy Steps

1. **Create PostgreSQL Database on Render**
   - Go to Render Dashboard
   - Create new PostgreSQL database
   - Note the connection details

2. **Create Web Service on Render**
   - Connect your GitHub repository
   - Select the `api-node` directory as root
   - Set build command: `npm install`
   - Set start command: `node index.js`
   - Add all environment variables above

3. **Update Database Connection**
   - The current code has hardcoded database credentials
   - Need to update to use environment variables

## Current Issues to Fix

1. Database connection is hardcoded in `index.js`
2. Missing environment variable configuration
3. Need to add health check endpoint
4. Missing production optimizations
