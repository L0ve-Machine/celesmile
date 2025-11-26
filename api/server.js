const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
require('dotenv').config();

// Initialize Stripe
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();

// Trust proxy (needed for nginx reverse proxy)
app.set('trust proxy', 1);

// Strict CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    const allowedOrigins = [
      'https://celesmile.didit.me',
      'https://celesmile-demo.duckdns.org',
      'http://localhost:3000',
      'http://localhost:8080',
      process.env.FRONTEND_URL
    ].filter(Boolean);

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.warn(`🚫 CORS blocked origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
app.use(express.json());

// ========================================
// Rate Limiting & Security System
// ========================================

// In-memory stores for tracking failures
// In production, use Redis for distributed systems
const loginAttempts = new Map(); // Track login attempts by IP
const blockedDevices = new Map(); // Track blocked devices by IP
const lockedAccounts = new Map(); // Track locked accounts by email

// Configuration
const RATE_LIMIT_CONFIG = {
  MAX_LOGIN_ATTEMPTS: 5,           // Max failed attempts before account lock
  DEVICE_BLOCK_THRESHOLD: 10,      // Max failed attempts before device block
  ACCOUNT_LOCK_DURATION: 15 * 60 * 1000,  // 15 minutes
  DEVICE_BLOCK_DURATION: 60 * 60 * 1000,  // 1 hour
  ATTEMPT_WINDOW: 15 * 60 * 1000   // 15 minute window
};

// Helper function to get client identifier (IP + User-Agent)
const getClientId = (req) => {
  const ip = req.ip || req.connection.remoteAddress;
  const userAgent = req.headers['user-agent'] || 'unknown';
  return `${ip}:${userAgent}`;
};

// Helper function to check if device is blocked
const isDeviceBlocked = (clientId) => {
  const blockInfo = blockedDevices.get(clientId);
  if (!blockInfo) return false;

  const now = Date.now();
  if (now > blockInfo.blockedUntil) {
    blockedDevices.delete(clientId);
    return false;
  }

  return true;
};

// Helper function to check if account is locked
const isAccountLocked = (email) => {
  const lockInfo = lockedAccounts.get(email);
  if (!lockInfo) return false;

  const now = Date.now();
  if (now > lockInfo.lockedUntil) {
    lockedAccounts.delete(email);
    return false;
  }

  return true;
};

// Helper function to record login attempt
const recordLoginAttempt = (clientId, email, success) => {
  const now = Date.now();

  if (success) {
    // Clear attempts on successful login
    loginAttempts.delete(`${clientId}:${email}`);
    return;
  }

  // Record failed attempt
  const key = `${clientId}:${email}`;
  const attempts = loginAttempts.get(key) || [];

  // Remove old attempts outside the window
  const recentAttempts = attempts.filter(
    timestamp => now - timestamp < RATE_LIMIT_CONFIG.ATTEMPT_WINDOW
  );

  recentAttempts.push(now);
  loginAttempts.set(key, recentAttempts);

  // Check for account lock
  if (recentAttempts.length >= RATE_LIMIT_CONFIG.MAX_LOGIN_ATTEMPTS) {
    lockedAccounts.set(email, {
      lockedUntil: now + RATE_LIMIT_CONFIG.ACCOUNT_LOCK_DURATION,
      attempts: recentAttempts.length
    });
    console.warn(`🔒 Account locked: ${email} (${recentAttempts.length} failed attempts)`);
  }

  // Check for device block (count all attempts from this client)
  const allClientAttempts = Array.from(loginAttempts.entries())
    .filter(([k]) => k.startsWith(clientId))
    .flatMap(([, v]) => v)
    .filter(timestamp => now - timestamp < RATE_LIMIT_CONFIG.ATTEMPT_WINDOW);

  if (allClientAttempts.length >= RATE_LIMIT_CONFIG.DEVICE_BLOCK_THRESHOLD) {
    blockedDevices.set(clientId, {
      blockedUntil: now + RATE_LIMIT_CONFIG.DEVICE_BLOCK_DURATION,
      attempts: allClientAttempts.length
    });
    console.warn(`🚫 Device blocked: ${clientId} (${allClientAttempts.length} failed attempts)`);
  }
};

// Middleware to check device blocking
const checkDeviceBlock = (req, res, next) => {
  const clientId = getClientId(req);

  if (isDeviceBlocked(clientId)) {
    const blockInfo = blockedDevices.get(clientId);
    const remainingTime = Math.ceil((blockInfo.blockedUntil - Date.now()) / 1000 / 60);

    console.warn(`🚫 Blocked device attempted access: ${clientId}`);
    return res.status(429).json({
      error: 'Device temporarily blocked due to suspicious activity',
      type: 'DEVICE_BLOCKED',
      remainingMinutes: remainingTime,
      message: `Your device has been temporarily blocked. Please try again in ${remainingTime} minutes.`
    });
  }

  next();
};

// General API rate limiter (prevents DoS)
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    type: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict limiter for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs
  skipSuccessfulRequests: false,
  message: {
    error: 'Too many authentication attempts, please try again later.',
    type: 'AUTH_RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Speed limiter for authentication (slows down repeated requests)
const authSpeedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 3, // Allow 3 requests per windowMs at full speed
  delayMs: (used, req) => (used - 3) * 500, // Incremental delay
  maxDelayMs: 5000, // Maximum delay of 5 seconds
});

// Apply general rate limiting to all routes
app.use(generalLimiter);

// JWT Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Optional authentication middleware (doesn't fail if no token)
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token) {
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (!err) {
        req.user = user;
      }
    });
  }
  next();
};

// Configure multer for profile image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = '/var/www/celesmile/uploads/profiles';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    console.log('File upload attempt:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size
    });

    const allowedTypes = /jpeg|jpg|png|gif|webp|octet-stream/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype) || file.mimetype === 'application/octet-stream';

    // Accept if extension is valid, regardless of mimetype
    if (extname) {
      console.log('File accepted by extension');
      return cb(null, true);
    }

    console.log('File rejected');
    cb(new Error('Only image files are allowed'));
  }
});

// Configure multer for salon gallery images
const salonStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = '/var/www/celesmile/uploads/salons';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'salon-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const salonUpload = multer({
  storage: salonStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp|octet-stream/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    if (extname) {
      return cb(null, true);
    }
    cb(new Error('Only image files are allowed'));
  }
});

const pool = mysql.createPool({
  host: '127.0.0.1',
  user: 'celesmile',
  password: 'celesmile123',
  database: 'celesmile',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Get bookings by provider
app.get('/api/bookings/:providerId', authenticateToken, async (req, res) => {
  try {
    // Check if user is authorized to access this provider's data
    if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const [rows] = await pool.query(
      'SELECT * FROM bookings WHERE provider_id = ? ORDER BY booking_date DESC',
      [req.params.providerId]
    );
    res.json(rows);
  } catch (error) {
    console.error('Error fetching bookings:', error);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// Get revenue summary
app.get('/api/revenue-summary/:providerId', authenticateToken, async (req, res) => {
  // Check authorization
  if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized' });
  }
  try {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    const [thisMonth] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM revenues WHERE provider_id = ? AND YEAR(date) = ? AND MONTH(date) = ?',
      [req.params.providerId, currentYear, currentMonth]
    );

    const [pending] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM revenues WHERE provider_id = ? AND status = ?',
      [req.params.providerId, 'pending']
    );

    const [paid] = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM revenues WHERE provider_id = ? AND status = ?',
      [req.params.providerId, 'paid']
    );

    res.json({
      thisMonthTotal: parseInt(thisMonth[0].total) || 0,
      pendingTotal: parseInt(pending[0].total) || 0,
      paidTotal: parseInt(paid[0].total) || 0,
      totalRevenue: (parseInt(pending[0].total) || 0) + (parseInt(paid[0].total) || 0)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get salons by provider
app.get('/api/salons/:providerId', authenticateToken, async (req, res) => {
  // Check authorization
  if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized' });
  }
  try {
    const [rows] = await pool.query(
      'SELECT * FROM salons WHERE provider_id = ?',
      [req.params.providerId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single salon by ID
app.get('/api/salon/:salonId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM salons WHERE id = ?',
      [req.params.salonId]
    );
    if (rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Salon not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get services with filters
app.get('/api/services', async (req, res) => {
  try {
    const { category, subcategory, location, search, limit, date, timeRange } = req.query;
    console.log('🔍 /api/services called with params:', { category, subcategory, location, search, limit, date, timeRange });

    let query;
    const params = [];

    if (date) {
      // 日付が指定された場合、availability_calendarとJOINして空きがあるサービスのみ取得
      query = `
        SELECT DISTINCT s.*
        FROM services s
        INNER JOIN availability_calendar ac ON s.provider_id = ac.provider_id
        WHERE s.is_active = 1
          AND ac.date = ?
          AND ac.is_available = 1
      `;
      params.push(date);

      // 時間帯フィルター（例: "morning" -> 06:00-12:00）
      if (timeRange) {
        let timeCondition = '';
        switch (timeRange) {
          case 'morning':
            timeCondition = "AND ac.time_slot >= '06:00' AND ac.time_slot < '12:00'";
            break;
          case 'afternoon':
            timeCondition = "AND ac.time_slot >= '12:00' AND ac.time_slot < '18:00'";
            break;
          case 'evening':
            timeCondition = "AND ac.time_slot >= '18:00'";
            break;
        }
        query += timeCondition;
      }
    } else {
      query = 'SELECT * FROM services WHERE is_active = 1';
    }

    if (category) {
      query += ' AND s.category = ?';
      params.push(category);
    }
    if (subcategory) {
      query += ' AND s.subcategory = ?';
      params.push(subcategory);
    }
    if (location) {
      query += ' AND s.location = ?';
      params.push(location);
    }
    if (search) {
      if (date) {
        query += ' AND (s.title LIKE ? OR s.description LIKE ? OR s.provider_name LIKE ?)';
      } else {
        query += ' AND (title LIKE ? OR description LIKE ? OR provider_name LIKE ?)';
      }
      const searchPattern = `%${search}%`;
      params.push(searchPattern, searchPattern, searchPattern);
    }

    if (date) {
      query += ' ORDER BY s.rating DESC, s.reviews_count DESC';
    } else {
      query += ' ORDER BY rating DESC, reviews_count DESC';
    }

    if (limit) {
      query += ' LIMIT ?';
      params.push(parseInt(limit));
    }

    console.log('🔍 Executing query:', query);
    console.log('🔍 With params:', params);

    const [rows] = await pool.query(query, params);
    console.log(`🔍 Query returned ${rows.length} rows`);
    rows.forEach(row => {
      console.log(`  - ${row.id}: ${row.title} (provider: ${row.provider_id})`);
    });

    res.json(rows);
  } catch (error) {
    console.error('❌ Error in /api/services:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get single service by ID
app.get('/api/service/:id', async (req, res) => {
  try {
    const [serviceRows] = await pool.query('SELECT * FROM services WHERE id = ?', [req.params.id]);
    if (serviceRows.length > 0) {
      const service = serviceRows[0];

      // Also get menu details from service_menus if it exists
      const [menuRows] = await pool.query('SELECT * FROM service_menus WHERE id = ?', [req.params.id]);
      if (menuRows.length > 0) {
        const menu = menuRows[0];
        // Parse duration options into menu items
        if (menu.duration_options) {
          const durations = menu.duration_options.split(',').map(d => d.trim());
          service.menu_items = durations.map(duration => ({
            name: `${duration}分コース`,
            duration: `${duration}分`,
            price: service.price
          }));
        }
      } else {
        // Default menu item if no menu found
        service.menu_items = [{
          name: `${service.title}`,
          duration: '60分',
          price: service.price
        }];
      }

      console.log(`✅ Found service: ${service.id} - ${service.title} with ${service.menu_items.length} menu items`);
      res.json(service);
    } else {
      console.log(`❌ Service not found: ${req.params.id}`);
      res.status(404).json({ error: 'Service not found' });
    }
  } catch (error) {
    console.error('❌ Error in /api/service/:id:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create/Update salon
app.post('/api/salons', authenticateToken, async (req, res) => {
  try {
    const { id, provider_id, salon_name, category, prefecture, city, address, description, gallery_image_urls } = req.body;

    // Convert gallery_image_urls array to JSON string for MySQL
    const galleryImagesJson = gallery_image_urls ? JSON.stringify(gallery_image_urls) : null;

    console.log('Saving salon with gallery images:', galleryImagesJson);

    const [result] = await pool.query(
      'INSERT INTO salons (id, provider_id, salon_name, category, prefecture, city, address, description, gallery_image_urls) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE salon_name=?, category=?, prefecture=?, city=?, address=?, description=?, gallery_image_urls=?',
      [id, provider_id, salon_name, category, prefecture, city, address, description, galleryImagesJson,
       salon_name, category, prefecture, city, address, description, galleryImagesJson]
    );
    res.json({ success: true, id });
  } catch (error) {
    console.error('Error saving salon:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete salon
app.delete('/api/salons/:salonId', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM salons WHERE id = ?', [req.params.salonId]);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get availability calendar
app.get('/api/availability/:providerId', authenticateToken, async (req, res) => {
  console.log('🔍 DEBUG [API availability]: Request for provider:', req.params.providerId);
  console.log('🔍 DEBUG [API availability]: User ID:', req.user?.id);
  console.log('🔍 DEBUG [API availability]: User role:', req.user?.role);
  console.log('🔍 DEBUG [API availability]: Query params:', req.query);

  // 認証済みユーザーなら誰でも閲覧可能（購入者も含む）
  console.log('✅ DEBUG [API availability]: Access granted for viewing availability');

  try {
    const { date, duration } = req.query;
    const providerId = req.params.providerId;
    const requestedDuration = parseInt(duration) || 60;

    // 1. まずavailability_calendarから空きスロットを取得
    let query = 'SELECT * FROM availability_calendar WHERE provider_id = ? AND is_available = 1';
    const params = [providerId];

    if (date) {
      query += ' AND date = ?';
      params.push(date);
    } else {
      query += ' AND date >= CURDATE()';
    }

    query += ' ORDER BY date, time_slot';
    console.log('🔍 DEBUG [API availability]: SQL query:', query);

    const [availabilityRows] = await pool.query(query, params);
    console.log('🔍 DEBUG [API availability]: Found', availabilityRows.length, 'available slots');

    // 2. 予約済みのスロットを取得（confirmed, pending）
    let bookingQuery = `
      SELECT DATE(booking_date) as date, time_slot, end_time_slot, duration
      FROM bookings
      WHERE provider_id = ?
        AND status IN ('confirmed', 'pending')
    `;
    const bookingParams = [providerId];

    if (date) {
      bookingQuery += ' AND DATE(booking_date) = ?';
      bookingParams.push(date);
    } else {
      bookingQuery += ' AND DATE(booking_date) >= CURDATE()';
    }

    const [bookings] = await pool.query(bookingQuery, bookingParams);
    console.log('🔍 DEBUG [API availability]: Found', bookings.length, 'existing bookings');

    // 3. 予約とバッティングするスロットを除外
    const filteredSlots = availabilityRows.filter(slot => {
      const slotDate = new Date(slot.date).toISOString().split('T')[0];
      const slotStart = slot.time_slot.split('-')[0]; // "10:00-11:00" -> "10:00"
      const slotEnd = slot.time_slot.split('-')[1];   // "10:00-11:00" -> "11:00"

      // このスロットが予約と重複するかチェック
      const hasConflict = bookings.some(booking => {
        const bookingDate = new Date(booking.date).toISOString().split('T')[0];
        if (slotDate !== bookingDate) return false;

        const bookingStart = booking.time_slot;
        const bookingEnd = booking.end_time_slot || addMinutesToTime(booking.time_slot, booking.duration || 60);

        // 時間の重複チェック
        return timeOverlaps(slotStart, slotEnd, bookingStart, bookingEnd);
      });

      if (hasConflict) {
        console.log(`🚫 Slot ${slotDate} ${slot.time_slot} blocked by booking`);
        return false;
      }

      // 4. 施術時間に応じた連続スロットチェック
      // 90分以上の場合、次のスロットも空いている必要がある
      if (requestedDuration > 60) {
        const slotsNeeded = Math.ceil(requestedDuration / 60);
        const slotStartMinutes = timeToMinutes(slotStart);

        // 必要なスロット数分、連続して空いているかチェック
        for (let i = 1; i < slotsNeeded; i++) {
          const nextSlotStart = minutesToTime(slotStartMinutes + (i * 60));
          const nextSlotEnd = minutesToTime(slotStartMinutes + ((i + 1) * 60));

          // 次のスロットが空きリストにあるか
          const nextSlotAvailable = availabilityRows.some(s => {
            const sDate = new Date(s.date).toISOString().split('T')[0];
            const sStart = s.time_slot.split('-')[0];
            return sDate === slotDate && sStart === nextSlotStart;
          });

          if (!nextSlotAvailable) {
            console.log(`🚫 Slot ${slotDate} ${slot.time_slot} needs ${slotsNeeded} slots but next slot not available`);
            return false;
          }

          // 次のスロットが予約で埋まっていないか
          const nextSlotBooked = bookings.some(booking => {
            const bookingDate = new Date(booking.date).toISOString().split('T')[0];
            if (slotDate !== bookingDate) return false;

            const bookingStart = booking.time_slot;
            const bookingEnd = booking.end_time_slot || addMinutesToTime(booking.time_slot, booking.duration || 60);

            return timeOverlaps(nextSlotStart, nextSlotEnd, bookingStart, bookingEnd);
          });

          if (nextSlotBooked) {
            console.log(`🚫 Slot ${slotDate} ${slot.time_slot} - next slot ${nextSlotStart} is booked`);
            return false;
          }
        }
      }

      return true;
    });

    console.log('🔍 DEBUG [API availability]: Returning', filteredSlots.length, 'available slots after filtering');
    res.json(filteredSlots);
  } catch (error) {
    console.error('❌ DEBUG [API availability]: Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ヘルパー関数: 時間を分に変換
function timeToMinutes(time) {
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes;
}

// ヘルパー関数: 分を時間文字列に変換
function minutesToTime(minutes) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
}

// ヘルパー関数: 時間に分を追加
function addMinutesToTime(time, minutesToAdd) {
  return minutesToTime(timeToMinutes(time) + minutesToAdd);
}

// ヘルパー関数: 時間範囲の重複チェック
function timeOverlaps(start1, end1, start2, end2) {
  const s1 = timeToMinutes(start1);
  const e1 = timeToMinutes(end1);
  const s2 = timeToMinutes(start2);
  const e2 = timeToMinutes(end2);
  return s1 < e2 && e1 > s2;
}

// Update availability
app.post('/api/availability', authenticateToken, async (req, res) => {
  try {
    const { id, provider_id, date, time_slot, is_available } = req.body;
    console.log('POST /api/availability - Request body:', req.body);
    const [result] = await pool.query(
      'INSERT INTO availability_calendar (id, provider_id, date, time_slot, is_available) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE is_available=?',
      [id, provider_id, date, time_slot, is_available, is_available]
    );
    console.log('POST /api/availability - Success');
    res.json({ success: true, id });
  } catch (error) {
    console.error('POST /api/availability - Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Get chats for provider
app.get('/api/chats/:providerId', authenticateToken, async (req, res) => {
  // Check authorization
  if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized' });
  }
  try {
    const [rows] = await pool.query(
      'SELECT * FROM chats WHERE provider_id = ? ORDER BY created_at DESC',
      [req.params.providerId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send chat message
app.post('/api/chats', async (req, res) => {
  try {
    const { id, provider_id, user_id, sender_type, message } = req.body;
    const [result] = await pool.query(
      'INSERT INTO chats (id, provider_id, user_id, sender_type, message) VALUES (?, ?, ?, ?, ?)',
      [id, provider_id, user_id, sender_type, message]
    );
    res.json({ success: true, id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new booking
app.post('/api/bookings', async (req, res) => {
  try {
    const {
      id, provider_id, salon_id, service_id, customer_name,
      customer_phone, customer_email, user_id, service_name,
      booking_date, time_slot, duration, price, status, notes
    } = req.body;

    // end_time_slotを計算（例: 10:00 + 90分 = 11:30）
    let end_time_slot = null;
    if (time_slot && duration) {
      const [hours, minutes] = time_slot.split(':').map(Number);
      const startMinutes = hours * 60 + minutes;
      const endMinutes = startMinutes + parseInt(duration);
      const endHours = Math.floor(endMinutes / 60);
      const endMins = endMinutes % 60;
      end_time_slot = `${endHours.toString().padStart(2, '0')}:${endMins.toString().padStart(2, '0')}`;
    }

    await pool.query(
      `INSERT INTO bookings (
        id, provider_id, salon_id, service_id, customer_name,
        customer_phone, customer_email, user_id, service_name,
        booking_date, time_slot, duration, end_time_slot, price, status, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id, provider_id, salon_id, service_id, customer_name,
        customer_phone, customer_email, user_id, service_name,
        booking_date, time_slot, duration || 60, end_time_slot, price, status, notes
      ]
    );

    res.json({ success: true, id });
  } catch (error) {
    console.error('Error creating booking:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update booking status
app.patch('/api/bookings/:bookingId', async (req, res) => {
  try {
    const { status } = req.body;
    await pool.query(
      'UPDATE bookings SET status = ? WHERE id = ?',
      [status, req.params.bookingId]
    );
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create revenue record
app.post('/api/revenues', async (req, res) => {
  try {
    const { id, provider_id, booking_id, amount, date, status, payment_method } = req.body;

    await pool.query(
      `INSERT INTO revenues (id, provider_id, booking_id, amount, date, status, payment_method)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, provider_id, booking_id, amount, date, status, payment_method]
    );

    res.json({ success: true, id });
  } catch (error) {
    console.error('Error creating revenue:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get menus by salon
app.get('/api/menus/:salonId', authenticateToken, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM service_menus WHERE salon_id = ? ORDER BY created_at DESC',
      [req.params.salonId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create/Update menu
app.post('/api/menus', authenticateToken, async (req, res) => {
  try {
    const { id, provider_id, salon_id, menu_name, description, price, duration, category, service_areas, transportation_fee, duration_options, optional_services } = req.body;

    // Save to service_menus table
    await pool.query(
      'INSERT INTO service_menus (id, provider_id, salon_id, menu_name, description, price, duration, category, service_areas, transportation_fee, duration_options, optional_services) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE menu_name=?, description=?, price=?, duration=?, category=?, service_areas=?, transportation_fee=?, duration_options=?, optional_services=?',
      [id, provider_id, salon_id, menu_name, description, price, duration, category, service_areas, transportation_fee, duration_options, optional_services, menu_name, description, price, duration, category, service_areas, transportation_fee, duration_options, optional_services]
    );

    // Get salon info
    const [salonRows] = await pool.query('SELECT salon_name FROM salons WHERE id = ?', [salon_id]);
    const salonName = salonRows.length > 0 ? salonRows[0].salon_name : 'サロン';

    // Extract location from service_areas (first area)
    const location = service_areas ? service_areas.split(',')[0].trim() : '東京都';

    // Sync to services table for display in customer dashboard
    await pool.query(
      `INSERT INTO services (id, provider_id, salon_id, title, provider_name, provider_title, price, rating, reviews_count, category, subcategory, location, address, description, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, 5.0, 0, ?, '', ?, '', ?, 1)
       ON DUPLICATE KEY UPDATE
       title=?, provider_name=?, price=?, category=?, location=?, description=?`,
      [id, provider_id, salon_id, menu_name, salonName, category, `¥${price}`, category, location, description,
       menu_name, salonName, `¥${price}`, category, location, description]
    );

    console.log(`✅ Menu ${id} synced to services table`);
    res.json({ success: true, id });
  } catch (error) {
    console.error('❌ Error saving menu:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete menu
app.delete('/api/menus/:menuId', authenticateToken, async (req, res) => {
  try {
    await pool.query('DELETE FROM service_menus WHERE id = ?', [req.params.menuId]);
    // Also delete from services table
    await pool.query('DELETE FROM services WHERE id = ?', [req.params.menuId]);
    console.log(`✅ Menu ${req.params.menuId} deleted from both tables`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error deleting menu:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get provider by ID
app.get('/api/providers/:providerId', authenticateToken, async (req, res) => {
  // Check authorization
  if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized' });
  }
  try {
    const [rows] = await pool.query(
      'SELECT * FROM providers WHERE id = ?',
      [req.params.providerId]
    );
    if (rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Provider not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Provider login
app.post('/api/login', [
  checkDeviceBlock,
  authLimiter,
  authSpeedLimiter,
  body('email').trim().notEmpty(),  // Allow non-email usernames for testing
  body('password').notEmpty()
], async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { email, password } = req.body;
    const clientId = getClientId(req);

    // Check if account is locked
    if (isAccountLocked(email)) {
      const lockInfo = lockedAccounts.get(email);
      const remainingTime = Math.ceil((lockInfo.lockedUntil - Date.now()) / 1000 / 60);

      console.warn(`🔒 Login attempt to locked account: ${email}`);
      return res.status(423).json({
        success: false,
        error: 'Account temporarily locked',
        type: 'ACCOUNT_LOCKED',
        remainingMinutes: remainingTime,
        message: `This account has been temporarily locked due to multiple failed login attempts. Please try again in ${remainingTime} minutes.`
      });
    }

    // Get provider by email
    const [rows] = await pool.query(
      'SELECT * FROM providers WHERE email = ?',
      [email]
    );

    if (rows.length === 0) {
      // Record failed attempt
      recordLoginAttempt(clientId, email, false);

      // Get remaining attempts
      const attempts = loginAttempts.get(`${clientId}:${email}`) || [];
      const remaining = RATE_LIMIT_CONFIG.MAX_LOGIN_ATTEMPTS - attempts.length;

      return res.status(401).json({
        success: false,
        error: 'Invalid credentials',
        remainingAttempts: Math.max(0, remaining)
      });
    }

    const provider = rows[0];

    // Compare password with hashed password
    const passwordMatch = await bcrypt.compare(password, provider.password);

    if (!passwordMatch) {
      // Record failed attempt
      recordLoginAttempt(clientId, email, false);

      // Get remaining attempts
      const attempts = loginAttempts.get(`${clientId}:${email}`) || [];
      const remaining = RATE_LIMIT_CONFIG.MAX_LOGIN_ATTEMPTS - attempts.length;

      console.warn(`❌ Failed login attempt for ${email} from ${clientId} (${attempts.length} total attempts)`);

      return res.status(401).json({
        success: false,
        error: 'Invalid credentials',
        remainingAttempts: Math.max(0, remaining)
      });
    }

    // Successful login - clear attempts
    recordLoginAttempt(clientId, email, true);

    // Generate JWT token
    const token = jwt.sign(
      {
        id: provider.id,
        email: provider.email,
        role: 'provider'
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Remove password from response
    const { password: _, ...providerWithoutPassword } = provider;

    console.log(`✅ Successful login: ${email}, verified: ${provider.verified}`);

    // If not verified, don't return provider data (treat as customer)
    if (provider.verified === 0) {
      res.json({
        success: true,
        user: {
          email: provider.email,
          name: provider.name
        },
        token: token
      });
    } else {
      res.json({
        success: true,
        provider: providerWithoutPassword,
        token: token
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, error: 'Login failed' });
  }
});

// Upload profile image
app.post('/api/upload/profile-image', upload.single('image'), async (req, res) => {
  try {
    console.log('POST /api/upload/profile-image - File:', req.file);
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    const imageUrl = `/uploads/profiles/${req.file.filename}`;
    console.log('POST /api/upload/profile-image - Success:', imageUrl);
    res.json({ success: true, imageUrl });
  } catch (error) {
    console.error('POST /api/upload/profile-image - Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Update provider profile
app.patch('/api/providers/:providerId', authenticateToken, async (req, res) => {
  // Check authorization
  if (req.user.id !== req.params.providerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized' });
  }
  try {
    console.log('PATCH /api/providers/:providerId - Request body:', req.body);
    console.log('Provider ID:', req.params.providerId);
    const { name, title, email, phone, bio, profile_image } = req.body;
    await pool.query(
      'UPDATE providers SET name=?, title=?, email=?, phone=?, bio=?, profile_image=? WHERE id=?',
      [name, title, email, phone, bio, profile_image, req.params.providerId]
    );
    console.log('PATCH /api/providers/:providerId - Success');
    res.json({ success: true });
  } catch (error) {
    console.error('PATCH /api/providers/:providerId - Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Verify provider (set verified = 1)
app.patch('/api/providers/:providerId/verify', async (req, res) => {
  try {
    console.log('PATCH /api/providers/:providerId/verify - Provider ID:', req.params.providerId);
    await pool.query(
      'UPDATE providers SET verified = 1 WHERE id = ?',
      [req.params.providerId]
    );
    console.log('PATCH /api/providers/:providerId/verify - Success');
    res.json({ success: true });
  } catch (error) {
    console.error('PATCH /api/providers/:providerId/verify - Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Change provider password
app.patch('/api/providers/:providerId/password', [
  authenticateToken,
  body('current_password').notEmpty(),
  body('new_password').isLength({ min: 8 })
], async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    // Check if user is authorized to change this password
    if (req.user.id !== req.params.providerId) {
      return res.status(403).json({ success: false, error: 'Not authorized' });
    }

    console.log('PATCH /api/providers/:providerId/password - Request body:', req.body);
    console.log('Provider ID:', req.params.providerId);
    const { current_password, new_password } = req.body;

    // Get current password hash
    const [rows] = await pool.query(
      'SELECT password FROM providers WHERE id = ?',
      [req.params.providerId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Provider not found' });
    }

    // Verify current password
    const passwordMatch = await bcrypt.compare(current_password, rows[0].password);

    if (!passwordMatch) {
      console.log('PATCH /api/providers/:providerId/password - Current password incorrect');
      return res.status(401).json({ success: false, error: 'Current password is incorrect' });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // Update password
    await pool.query(
      'UPDATE providers SET password = ? WHERE id = ?',
      [hashedPassword, req.params.providerId]
    );

    console.log('PATCH /api/providers/:providerId/password - Success');
    res.json({ success: true });
  } catch (error) {
    console.error('PATCH /api/providers/:providerId/password - Error:', error.message);
    res.status(500).json({ success: false, error: 'Password change failed' });
  }
});

// Create a new review
app.post('/api/reviews', async (req, res) => {
  try {
    console.log('POST /api/reviews - Request body:', req.body);
    const { id, booking_id, provider_id, service_id, customer_name, rating, comment } = req.body;

    // Check if review already exists for this booking
    const [existing] = await pool.query(
      'SELECT id FROM reviews WHERE booking_id = ?',
      [booking_id]
    );

    if (existing.length > 0) {
      console.log('POST /api/reviews - Review already exists for this booking');
      return res.status(400).json({ error: 'Review already exists for this booking' });
    }

    await pool.query(
      'INSERT INTO reviews (id, booking_id, provider_id, service_id, customer_name, rating, comment) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, booking_id, provider_id, service_id, customer_name, rating, comment]
    );
    console.log('POST /api/reviews - Success');
    res.json({ success: true, id });
  } catch (error) {
    console.error('POST /api/reviews - Error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for a service
app.get('/api/reviews/service/:serviceId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM reviews WHERE service_id = ? ORDER BY created_at DESC',
      [req.params.serviceId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get reviews for a provider
app.get('/api/reviews/provider/:providerId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM reviews WHERE provider_id = ? ORDER BY created_at DESC',
      [req.params.providerId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Check if review exists for a booking
app.get('/api/reviews/booking/:bookingId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM reviews WHERE booking_id = ?',
      [req.params.bookingId]
    );
    res.json({ exists: rows.length > 0, review: rows[0] || null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ========================================
// Stripe Connect API Endpoints
// ========================================

// Create Stripe Connect Account for Provider
app.post('/api/stripe/connect/account', authenticateToken, async (req, res) => {
  try {
    const { email, providerId } = req.body;

    // Create a Connect Express account with manual payout schedule
    // 翌月25日払いを実現するため、手動送金モードに設定
    // 毎月25日にバッチ処理で送金を実行する
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'JP',
      email: email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      settings: {
        payouts: {
          schedule: {
            interval: 'manual', // 手動送金モード（翌月25日払い対応）
          },
        },
      },
    });

    // Store stripe_account_id in database
    await pool.query(
      'UPDATE providers SET stripe_account_id = ? WHERE id = ?',
      [account.id, providerId]
    );

    res.json({
      success: true,
      accountId: account.id,
      message: 'Stripe Connect account created'
    });
  } catch (error) {
    console.error('Error creating Stripe Connect account:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create Account Link for onboarding
app.post('/api/stripe/connect/account-link', authenticateToken, async (req, res) => {
  try {
    const { accountId } = req.body;

    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `${process.env.FRONTEND_URL}/provider/settings`,
      return_url: `${process.env.FRONTEND_URL}/provider/settings?onboarding=complete`,
      type: 'account_onboarding',
    });

    res.json({ url: accountLink.url });
  } catch (error) {
    console.error('Error creating account link:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get Stripe Account status
app.get('/api/stripe/connect/account/:accountId', authenticateToken, async (req, res) => {
  try {
    const account = await stripe.accounts.retrieve(req.params.accountId);

    res.json({
      id: account.id,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
    });
  } catch (error) {
    console.error('Error retrieving account:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create Payment Intent with Application Fee (Direct Charge)
app.post('/api/stripe/payment-intent', async (req, res) => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔵 Payment Intent Request Received');
  console.log('Request body:', JSON.stringify(req.body, null, 2));

  try {
    const { amount, providerId } = req.body;
    console.log(`📊 Amount: ${amount}, Provider ID: ${providerId}`);

    // Get provider's stripe_account_id
    const [rows] = await pool.query(
      'SELECT stripe_account_id FROM providers WHERE id = ?',
      [providerId]
    );
    console.log(`🔍 DB Query result:`, rows);

    if (rows.length === 0 || !rows[0].stripe_account_id) {
      console.log('❌ Provider Stripe account not found');
      return res.status(400).json({ error: 'Provider Stripe account not found' });
    }

    const stripeAccountId = rows[0].stripe_account_id;
    console.log(`✅ Stripe Account ID: ${stripeAccountId}`);

    // Calculate application fee (20%)
    const applicationFee = Math.round(amount * parseFloat(process.env.APPLICATION_FEE_PERCENTAGE || 0.20));
    console.log(`💰 Application Fee: ${applicationFee} (${process.env.APPLICATION_FEE_PERCENTAGE * 100}%)`);

    // Create Payment Intent on connected account (Direct Charge)
    console.log('🔄 Creating Payment Intent with Stripe...');
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'jpy',
      application_fee_amount: applicationFee,
      automatic_payment_methods: {
        enabled: true,
      },
    }, {
      stripeAccount: stripeAccountId, // This makes it a Direct Charge
    });

    console.log('✅ Payment Intent created:', paymentIntent.id);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    res.json({
      clientSecret: paymentIntent.client_secret,
      applicationFee: applicationFee,
    });
  } catch (error) {
    console.error('❌ Error creating payment intent:', error.message);
    console.error('Full error:', error);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    res.status(500).json({ error: error.message });
  }
});

// Confirm Payment Intent with saved payment method (for Connected Account)
app.post('/api/stripe/confirm-payment-intent', async (req, res) => {
  try {
    const { paymentIntentId, paymentMethodId, providerId } = req.body;
    console.log('🔵 Confirming Payment Intent:', paymentIntentId);

    // Get provider's stripe_account_id
    const [rows] = await pool.query(
      'SELECT stripe_account_id FROM providers WHERE id = ?',
      [providerId]
    );

    if (rows.length === 0 || !rows[0].stripe_account_id) {
      return res.status(400).json({ error: 'Provider Stripe account not found' });
    }

    const stripeAccountId = rows[0].stripe_account_id;

    // Confirm the PaymentIntent on the connected account
    const paymentIntent = await stripe.paymentIntents.confirm(
      paymentIntentId,
      {
        payment_method: paymentMethodId,
      },
      {
        stripeAccount: stripeAccountId, // Important: specify connected account
      }
    );

    console.log('✅ Payment confirmed:', paymentIntent.status);

    res.json({
      success: paymentIntent.status === 'succeeded',
      status: paymentIntent.status,
    });
  } catch (error) {
    console.error('❌ Error confirming payment:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// Get payout schedule for a connected account
app.get('/api/stripe/connect/payout-schedule/:accountId', async (req, res) => {
  try {
    const account = await stripe.accounts.retrieve(req.params.accountId);

    res.json({
      interval: account.settings?.payouts?.schedule?.interval || 'daily',
      monthly_anchor: account.settings?.payouts?.schedule?.monthly_anchor,
      delay_days: account.settings?.payouts?.schedule?.delay_days,
    });
  } catch (error) {
    console.error('Error retrieving payout schedule:', error);
    res.status(500).json({ error: error.message });
  }
});

// Upload salon gallery images (max 5)
app.post('/api/upload/salon-images', salonUpload.array('images', 5), (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No files uploaded' });
    }

    const imageUrls = req.files.map(file => `/uploads/salons/${file.filename}`);

    console.log(`✅ Uploaded ${req.files.length} salon images:`, imageUrls);

    res.json({
      success: true,
      imageUrls: imageUrls,
      count: req.files.length
    });
  } catch (error) {
    console.error('Error uploading salon images:', error);
    res.status(500).json({ error: error.message });
  }
});

// DID-IT Webhook endpoint for provider verification
app.post('/api/didit/webhook', async (req, res) => {
  console.log('🔔 DID-IT Webhook received');
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  console.log('Body:', JSON.stringify(req.body, null, 2));

  // Return 200 immediately
  res.status(200).json({ success: true, message: 'Webhook received' });

  // Process the webhook data
  try {
    const { session_id, status, decision, vendor_data } = req.body;

    console.log('📊 Webhook Data:');
    console.log('  Session ID:', session_id);
    console.log('  Status:', status);
    console.log('  Decision:', decision);
    console.log('  Vendor Data:', vendor_data);

    // Store verification result in database if needed
    // TODO: Update provider verification status in database

  } catch (error) {
    console.error('❌ Error processing webhook:', error);
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});
