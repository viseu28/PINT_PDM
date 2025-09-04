const multer = require('multer');
const { CloudinaryStorage } = require('@fluidjs/multer-cloudinary');
const cloudinary = require('cloudinary').v2;

// Configura o Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configura o Multer para usar o Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'projetos_escola',
    resource_type: 'image',
    format: 'pdf',  // força o Cloudinary a salvar com extensão .pdf
    allowed_formats: ['pdf', 'zip', 'docx', 'txt'],
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

module.exports = upload;