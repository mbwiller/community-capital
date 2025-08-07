// server.js - Production-Ready Backend with Railway Deployment
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const http = require('http');
const Redis = require('redis');
const Bull = require('bull');
const winston = require('winston');
const morgan = require('morgan');
require('dotenv').config();

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize WebSocket with Redis adapter for scaling
const io = new Server(server, {
  cors: {
    origin: process.env.CLIENT_URL || 'http://localhost:3000',
    credentials: true
  },
  adapter: require('socket.io-redis')({
    host: process.env.REDIS_URL,
    port: 6379
  })
});

// Initialize Redis client
const redis = Redis.createClient({
  url: process.env.REDIS_URL,
  retry_strategy: (options) => {
    if (options.error && options.error.code === 'ECONNREFUSED') {
      return new Error('Redis connection refused');
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      return new Error('Redis retry time exhausted');
    }
    if (options.attempt > 10) {
      return undefined;
    }
    return Math.min(options.attempt * 100, 3000);
  }
});

// Initialize Bull queue for background jobs
const paymentQueue = new Bull('payment-processing', process.env.REDIS_URL);
const notificationQueue = new Bull('notifications', process.env.REDIS_URL);
const analyticsQueue = new Bull('analytics', process.env.REDIS_URL);

// Logger configuration
const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'community-capital-api' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

app.use(compression());
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true,
  optionsSuccessStatus: 200
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use(morgan('combined', {
  stream: { write: message => logger.info(message.trim()) }
}));

// Rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      error: 'Too many requests, please try again later'
    });
  }
});

const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true
});

app.use('/api/', apiLimiter);
app.use('/api/payments/', paymentLimiter);

// Import services
const stripeService = require('./services/stripe.service');
const plaidService = require('./services/plaid.service');
const twilioService = require('./services/twilio.service');
const analyticsService = require('./services/analytics.service');

// Import middleware
const { authenticate, authorize } = require('./middleware/auth.middleware');
const { validateRequest } = require('./middleware/validation.middleware');
const { idempotency } = require('./middleware/idempotency.middleware');

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV
  });
});

// ==================== AUTH ROUTES ====================

app.post('/api/auth/register', validateRequest('register'), async (req, res, next) => {
  try {
    const { phoneNumber } = req.body;
    
    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store OTP in Redis with 5-minute expiry
    await redis.setex(`otp:${phoneNumber}`, 300, otp);
    
    // Send SMS via Twilio
    await twilioService.sendSMS(phoneNumber, `Your Community Capital code is: ${otp}`);
    
    // Log for analytics
    analyticsQueue.add('track', {
      event: 'user_registration_started',
      properties: { phoneNumber: phoneNumber.slice(-4) }
    });
    
    res.json({
      success: true,
      message: 'OTP sent successfully'
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/verify', validateRequest('verifyOTP'), async (req, res, next) => {
  try {
    const { phoneNumber, code } = req.body;
    
    // Verify OTP from Redis
    const storedOTP = await redis.get(`otp:${phoneNumber}`);
    
    if (!storedOTP || storedOTP !== code) {
      return res.status(401).json({
        error: 'Invalid or expired OTP'
      });
    }
    
    // Create or get user
    let user = await db.users.findByPhone(phoneNumber);
    if (!user) {
      user = await db.users.create({
        phoneNumber,
        createdAt: new Date()
      });
    }
    
    // Generate JWT
    const token = jwt.sign(
      { userId: user.id, phoneNumber },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Clean up OTP
    await redis.del(`otp:${phoneNumber}`);
    
    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        phoneNumber: user.phoneNumber,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    next(error);
  }
});

// ==================== EVENT ROUTES ====================

app.post('/api/events', authenticate, validateRequest('createEvent'), async (req, res, next) => {
  try {
    const { name, restaurant, items, receiptImageId } = req.body;
    const userId = req.user.id;
    
    // Generate unique event code
    const eventCode = generateEventCode();
    
    // Create event in database
    const event = await db.events.create({
      creatorId: userId,
      eventName: name,
      restaurantName: restaurant,
      code: eventCode,
      items: items,
      status: 'draft',
      createdAt: new Date()
    });
    
    // Emit to WebSocket for real-time updates
    io.to(`user:${userId}`).emit('eventCreated', event);
    
    // Track analytics
    analyticsQueue.add('track', {
      userId,
      event: 'event_created',
      properties: {
        eventId: event.id,
        itemCount: items.length,
        hasReceipt: !!receiptImageId
      }
    });
    
    res.json({
      success: true,
      event
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/events/join', authenticate, async (req, res, next) => {
  try {
    const { code } = req.body;
    const userId = req.user.id;
    
    // Find event by code
    const event = await db.events.findByCode(code);
    
    if (!event) {
      return res.status(404).json({
        error: 'Event not found'
      });
    }
    
    // Add participant
    await db.participants.create({
      eventId: event.id,
      userId,
      joinedAt: new Date()
    });
    
    // Notify all participants
    io.to(`event:${event.id}`).emit('participantJoined', {
      userId,
      userName: req.user.name
    });
    
    res.json({
      success: true,
      event
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/events/:eventId/claim', authenticate, async (req, res, next) => {
  try {
    const { eventId } = req.params;
    const { items } = req.body;
    const userId = req.user.id;
    
    // Update item claims
    await db.claims.upsert({
      eventId,
      userId,
      items,
      claimedAt: new Date()
    });
    
    // Calculate new totals
    const totals = await calculateEventTotals(eventId);
    
    // Broadcast to all participants
    io.to(`event:${eventId}`).emit('itemsClaimed', {
      userId,
      items,
      totals
    });
    
    res.json({
      success: true,
      totals
    });
  } catch (error) {
    next(error);
  }
});

// ==================== PAYMENT ROUTES ====================

app.post('/api/payments/link-bank', authenticate, idempotency, async (req, res, next) => {
  try {
    const { publicToken } = req.body;
    const userId = req.user.id;
    
    // Exchange Plaid public token
    const { accessToken, itemId, accounts } = await plaidService.exchangePublicToken(publicToken);
    
    // Create Stripe bank account token
    const bankAccountToken = await plaidService.createStripeBankToken(accessToken, accounts[0].account_id);
    
    // Store securely
    await db.bankAccounts.create({
      userId,
      plaidItemId: itemId,
      stripeBankToken: bankAccountToken,
      accountMask: accounts[0].mask,
      institutionName: accounts[0].institution_name
    });
    
    res.json({
      success: true,
      account: {
        mask: accounts[0].mask,
        institution: accounts[0].institution_name
      }
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/payments/charge', authenticate, paymentLimiter, idempotency, async (req, res, next) => {
  try {
    const { eventId, confirmationToken } = req.body;
    const userId = req.user.id;
    
    // Get user's payment method
    const bankAccount = await db.bankAccounts.findByUserId(userId);
    if (!bankAccount) {
      return res.status(400).json({
        error: 'No linked bank account'
      });
    }
    
    // Get user's share amount
    const share = await db.claims.getUserShare(eventId, userId);
    
    // Queue payment processing
    const job = await paymentQueue.add('processPayment', {
      userId,
      eventId,
      amount: share.totalOwed,
      bankToken: bankAccount.stripeBankToken
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    });
    
    res.json({
      success: true,
      jobId: job.id,
      message: 'Payment processing initiated'
    });
  } catch (error) {
    next(error);
  }
});

// ==================== WEBSOCKET HANDLERS ====================

io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

io.on('connection', (socket) => {
  logger.info(`User ${socket.userId} connected`);
  
  // Join user room
  socket.join(`user:${socket.userId}`);
  
  // Join event rooms
  socket.on('joinEvent', (eventId) => {
    socket.join(`event:${eventId}`);
  });
  
  // Handle real-time updates
  socket.on('updateClaim', async (data) => {
    const { eventId, items } = data;
    
    // Broadcast to event room
    socket.to(`event:${eventId}`).emit('claimUpdated', {
      userId: socket.userId,
      items
    });
  });
  
  socket.on('disconnect', () => {
    logger.info(`User ${socket.userId} disconnected`);
  });
});

// ==================== QUEUE PROCESSORS ====================

paymentQueue.process('processPayment', async (job) => {
  const { userId, eventId, amount, bankToken } = job.data;
  
  try {
    // Create ACH charge with Stripe
    const charge = await stripeService.createACHCharge({
      amount: Math.round(amount * 100), // Convert to cents
      source: bankToken,
      metadata: {
        userId,
        eventId
      }
    });
    
    // Update payment status
    await db.payments.create({
      userId,
      eventId,
      stripeChargeId: charge.id,
      amount,
      status: 'processing'
    });
    
    // Notify user
    io.to(`user:${userId}`).emit('paymentProcessing', {
      eventId,
      chargeId: charge.id
    });
    
    // Check if all participants have paid
    const allPaid = await checkAllParticipantsPaid(eventId);
    if (allPaid) {
      // Create virtual card and pay merchant
      await processGroupPayment(eventId);
    }
    
    return { success: true, chargeId: charge.id };
  } catch (error) {
    logger.error('Payment processing failed:', error);
    throw error;
  }
});

notificationQueue.process('sendNotification', async (job) => {
  const { type, recipient, data } = job.data;
  
  switch (type) {
    case 'sms':
      await twilioService.sendSMS(recipient, data.message);
      break;
    case 'push':
      // Implement push notifications
      break;
    case 'email':
      // Implement email notifications
      break;
  }
});

analyticsQueue.process('track', async (job) => {
  const { event, userId, properties } = job.data;
  
  // Send to analytics service (Mixpanel, Segment, etc.)
  await analyticsService.track({
    event,
    userId,
    properties,
    timestamp: new Date()
  });
  
  // Store in database for ML training
  await db.analytics.create({
    event,
    userId,
    properties,
    timestamp: new Date()
  });
});

// ==================== ERROR HANDLING ====================

app.use((err, req, res, next) => {
  logger.error({
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip
  });
  
  // Send error to Sentry
  if (process.env.NODE_ENV === 'production') {
    Sentry.captureException(err);
  }
  
  // Don't leak error details in production
  const message = process.env.NODE_ENV === 'production' 
    ? 'An error occurred' 
    : err.message;
  
  res.status(err.status || 500).json({
    error: message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// ==================== HELPER FUNCTIONS ====================

function generateEventCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

async function calculateEventTotals(eventId) {
  const event = await db.events.findById(eventId);
  const claims = await db.claims.findByEventId(eventId);
  const participants = await db.participants.findByEventId(eventId);
  
  // Calculate each participant's share
  const totals = {};
  
  for (const participant of participants) {
    const userClaims = claims.filter(c => c.userId === participant.userId);
    const subtotal = userClaims.reduce((sum, claim) => {
      return sum + event.items.find(i => i.id === claim.itemId).price;
    }, 0);
    
    const taxShare = (subtotal / event.subtotal) * event.tax;
    const tipShare = subtotal * (event.tipPercentage / 100);
    
    totals[participant.userId] = {
      subtotal,
      tax: taxShare,
      tip: tipShare,
      total: subtotal + taxShare + tipShare
    };
  }
  
  return totals;
}

async function checkAllParticipantsPaid(eventId) {
  const participants = await db.participants.findByEventId(eventId);
  const payments = await db.payments.findByEventId(eventId);
  
  return participants.every(p => 
    payments.some(pay => pay.userId === p.userId && pay.status === 'processing')
  );
}

async function processGroupPayment(eventId) {
  const event = await db.events.findById(eventId);
  const payments = await db.payments.findByEventId(eventId);
  
  const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);
  
  // Create virtual card with Stripe Issuing
  const card = await stripeService.createVirtualCard({
    amount: Math.round(totalAmount * 100),
    currency: 'usd',
    metadata: {
      eventId,
      merchantName: event.restaurantName
    }
  });
  
  // Update event with virtual card
  await db.events.update(eventId, {
    virtualCardId: card.id,
    status: 'completed'
  });
  
  // Notify all participants
  io.to(`event:${eventId}`).emit('paymentCompleted', {
    cardLast4: card.last4,
    totalAmount
  });
  
  return card;
}

// ==================== DATABASE MOCK (Replace with real DB) ====================

const db = {
  users: {
    findByPhone: async (phone) => { /* Implement */ },
    create: async (data) => { /* Implement */ }
  },
  events: {
    create: async (data) => { /* Implement */ },
    findByCode: async (code) => { /* Implement */ },
    findById: async (id) => { /* Implement */ },
    update: async (id, data) => { /* Implement */ }
  },
  participants: {
    create: async (data) => { /* Implement */ },
    findByEventId: async (eventId) => { /* Implement */ }
  },
  claims: {
    upsert: async (data) => { /* Implement */ },
    findByEventId: async (eventId) => { /* Implement */ },
    getUserShare: async (eventId, userId) => { /* Implement */ }
  },
  bankAccounts: {
    create: async (data) => { /* Implement */ },
    findByUserId: async (userId) => { /* Implement */ }
  },
  payments: {
    create: async (data) => { /* Implement */ },
    findByEventId: async (eventId) => { /* Implement */ }
  },
  analytics: {
    create: async (data) => { /* Implement */ }
  }
};

// ==================== SERVER STARTUP ====================

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`📦 Environment: ${process.env.NODE_ENV}`);
  logger.info(`🔌 WebSocket enabled`);
  logger.info(`📊 Redis connected: ${redis.connected}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  
  server.close(() => {
    logger.info('HTTP server closed');
  });
  
  await paymentQueue.close();
  await notificationQueue.close();
  await analyticsQueue.close();
  await redis.quit();
  
  process.exit(0);
});

module.exports = app;