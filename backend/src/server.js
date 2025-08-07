const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', message: 'Server is running!' });
});

// Test endpoint for auth
app.post('/api/auth/register', (req, res) => {
  const { phoneNumber } = req.body;
  console.log('📱 Registration request for:', phoneNumber);
  
  // For testing, just return success
  const otp = '123456';
  console.log('🔑 OTP Code:', otp);
  
  res.json({ 
    success: true, 
    message: 'OTP sent (check console for code)' 
  });
});

app.post('/api/auth/verify', (req, res) => {
  const { code } = req.body;
  
  if (code === '123456') {
    res.json({
      success: true,
      token: 'test-jwt-token',
      user: {
        id: '123',
        phoneNumber: '+1234567890'
      }
    });
  } else {
    res.status(401).json({ error: 'Invalid OTP' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV}`);
  console.log(`✅ Health check: http://localhost:${PORT}/health`);
});
