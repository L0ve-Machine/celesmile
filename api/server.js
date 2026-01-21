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
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 1000, // Limit each IP to 1000 requests per minute
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

    // 1クエリで全ての集計を取得（パフォーマンス改善: 3回→1回）
    const [result] = await pool.query(
      `SELECT
        COALESCE(SUM(CASE WHEN YEAR(date) = ? AND MONTH(date) = ? THEN amount ELSE 0 END), 0) as thisMonthTotal,
        COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0) as pendingTotal,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0) as paidTotal
      FROM revenues
      WHERE provider_id = ?`,
      [currentYear, currentMonth, req.params.providerId]
    );

    const thisMonthTotal = parseInt(result[0].thisMonthTotal) || 0;
    const pendingTotal = parseInt(result[0].pendingTotal) || 0;
    const paidTotal = parseInt(result[0].paidTotal) || 0;

    res.json({
      thisMonthTotal,
      pendingTotal,
      paidTotal,
      totalRevenue: pendingTotal + paidTotal
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
      query = 'SELECT * FROM services s WHERE s.is_active = 1';
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
      query += ' AND (s.title LIKE ? OR s.description LIKE ? OR s.provider_name LIKE ?)';
      const searchPattern = `%${search}%`;
      params.push(searchPattern, searchPattern, searchPattern);
    }

    query += ' ORDER BY s.rating DESC, s.reviews_count DESC';

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

// Send chat message (legacy - keep for backwards compatibility)
app.post('/api/chats', async (req, res) => {
  try {
    const { id, provider_id, user_id, sender_type, message, chat_room_id } = req.body;
    const [result] = await pool.query(
      'INSERT INTO chats (id, chat_room_id, provider_id, user_id, sender_type, message) VALUES (?, ?, ?, ?, ?, ?)',
      [id, chat_room_id, provider_id, user_id, sender_type, message]
    );
    res.json({ success: true, id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== Chat Room APIs ====================

// Create chat room
app.post('/api/chat-rooms', async (req, res) => {
  try {
    const { id, provider_id, user_id, booking_id } = req.body;

    // Check if room already exists for this provider-user pair
    const [existing] = await pool.query(
      'SELECT * FROM chat_rooms WHERE provider_id = ? AND user_id = ?',
      [provider_id, user_id]
    );

    if (existing.length > 0) {
      // Return existing room
      return res.json({ success: true, id: existing[0].id, existing: true });
    }

    // Create new room
    await pool.query(
      'INSERT INTO chat_rooms (id, provider_id, user_id, booking_id) VALUES (?, ?, ?, ?)',
      [id, provider_id, user_id, booking_id]
    );
    res.json({ success: true, id, existing: false });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get chat rooms for provider
app.get('/api/chat-rooms/provider/:providerId', authenticateToken, async (req, res) => {
  try {
    const { providerId } = req.params;

    // Check authorization
    if (req.user.id !== providerId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const [rooms] = await pool.query(`
      SELECT
        cr.id,
        cr.provider_id,
        cr.user_id,
        cr.booking_id,
        cr.created_at,
        p.name as provider_name,
        b.service_name,
        (SELECT message FROM chats WHERE chat_room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message,
        (SELECT created_at FROM chats WHERE chat_room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
        (SELECT COUNT(*) FROM chats WHERE chat_room_id = cr.id AND sender_type = 'user') as unread_count
      FROM chat_rooms cr
      LEFT JOIN providers p ON cr.provider_id = p.id
      LEFT JOIN bookings b ON cr.booking_id = b.id
      WHERE cr.provider_id = ?
      ORDER BY last_message_time DESC
    `, [providerId]);

    res.json(rooms);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get chat rooms for user (customer)
app.get('/api/chat-rooms/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const [rooms] = await pool.query(`
      SELECT
        cr.id,
        cr.provider_id,
        cr.user_id,
        cr.booking_id,
        cr.created_at,
        p.name as provider_name,
        b.service_name,
        (SELECT message FROM chats WHERE chat_room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message,
        (SELECT created_at FROM chats WHERE chat_room_id = cr.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
        (SELECT COUNT(*) FROM chats WHERE chat_room_id = cr.id AND sender_type = 'provider') as unread_count
      FROM chat_rooms cr
      LEFT JOIN providers p ON cr.provider_id = p.id
      LEFT JOIN bookings b ON cr.booking_id = b.id
      WHERE cr.user_id = ?
      ORDER BY last_message_time DESC
    `, [userId]);

    res.json(rooms);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get chat room by ID
app.get('/api/chat-rooms/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;

    const [rooms] = await pool.query(`
      SELECT
        cr.id,
        cr.provider_id,
        cr.user_id,
        cr.booking_id,
        cr.created_at,
        p.name as provider_name,
        b.service_name
      FROM chat_rooms cr
      LEFT JOIN providers p ON cr.provider_id = p.id
      LEFT JOIN bookings b ON cr.booking_id = b.id
      WHERE cr.id = ?
    `, [roomId]);

    if (rooms.length === 0) {
      return res.status(404).json({ error: 'Chat room not found' });
    }

    res.json(rooms[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get messages for a chat room
app.get('/api/chat-rooms/:roomId/messages', async (req, res) => {
  try {
    const { roomId } = req.params;

    const [messages] = await pool.query(`
      SELECT
        c.id,
        c.chat_room_id,
        c.provider_id,
        c.user_id,
        c.sender_type,
        c.message,
        c.created_at,
        CASE
          WHEN c.sender_type = 'provider' THEN p.name
          ELSE c.user_id
        END as sender_name
      FROM chats c
      LEFT JOIN providers p ON c.provider_id = p.id
      WHERE c.chat_room_id = ?
      ORDER BY c.created_at ASC
    `, [roomId]);

    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message to a chat room
app.post('/api/chat-rooms/:roomId/messages', async (req, res) => {
  try {
    const { roomId } = req.params;
    const { sender_type, message } = req.body;

    // Get chat room info
    const [rooms] = await pool.query(
      'SELECT provider_id, user_id FROM chat_rooms WHERE id = ?',
      [roomId]
    );

    if (rooms.length === 0) {
      return res.status(404).json({ error: 'Chat room not found' });
    }

    const room = rooms[0];
    const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    await pool.query(
      'INSERT INTO chats (id, chat_room_id, provider_id, user_id, sender_type, message) VALUES (?, ?, ?, ?, ?, ?)',
      [messageId, roomId, room.provider_id, room.user_id, sender_type, message]
    );

    res.json({ success: true, id: messageId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== End Chat Room APIs ====================

// Create new booking
app.post('/api/bookings', async (req, res) => {
  try {
    const {
      id, provider_id, salon_id, service_id, customer_name,
      customer_phone, customer_email, user_id, service_name,
      booking_date, time_slot, duration, price, status, notes,
      payment_intent_id, stripe_account_id, amount
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
        booking_date, time_slot, duration, end_time_slot, price, status, notes,
        payment_intent_id, stripe_account_id, amount
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id, provider_id, salon_id, service_id, customer_name,
        customer_phone, customer_email, user_id, service_name,
        booking_date, time_slot, duration || 60, end_time_slot, price, status, notes,
        payment_intent_id || null, stripe_account_id || null, amount || price
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

// Cancel booking with refund logic (180分ルール適用)
app.post('/api/bookings/:bookingId/cancel', async (req, res) => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔴 Booking Cancellation Request');

  try {
    const { bookingId } = req.params;
    const { reason } = req.body;

    // 1. 予約情報を取得
    const [rows] = await pool.query(
      'SELECT * FROM bookings WHERE id = ?',
      [bookingId]
    );

    if (rows.length === 0) {
      console.log('❌ Booking not found:', bookingId);
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = rows[0];
    console.log('📋 Booking found:', {
      id: booking.id,
      booking_date: booking.booking_date,
      time_slot: booking.time_slot,
      payment_intent_id: booking.payment_intent_id,
      amount: booking.amount
    });

    // 既にキャンセル済みの場合
    if (booking.status === 'cancelled') {
      return res.status(400).json({ error: 'Booking is already cancelled' });
    }

    // 2. 180分ルールをチェック
    // 予約日時を作成（booking_date + time_slot）
    const bookingDate = new Date(booking.booking_date);
    const [hours, minutes] = booking.time_slot.split(':').map(Number);
    bookingDate.setHours(hours, minutes, 0, 0);

    const now = new Date();
    const diffMinutes = (bookingDate - now) / (1000 * 60);

    console.log('⏰ Time check:', {
      bookingDateTime: bookingDate.toISOString(),
      now: now.toISOString(),
      diffMinutes: Math.round(diffMinutes),
      canRefund: diffMinutes >= 180
    });

    let refundResult = null;
    let refundAmount = 0;
    const canRefund = diffMinutes >= 180;

    // 3. 返金処理（180分以上前の場合のみ）
    if (canRefund && booking.payment_intent_id && booking.stripe_account_id) {
      try {
        console.log('💰 Processing refund...');

        // Stripe Refund API (Connected Account用)
        const refund = await stripe.refunds.create({
          payment_intent: booking.payment_intent_id,
        }, {
          stripeAccount: booking.stripe_account_id,
        });

        refundResult = {
          id: refund.id,
          amount: refund.amount,
          status: refund.status
        };
        refundAmount = refund.amount;

        console.log('✅ Refund successful:', refundResult);
      } catch (refundError) {
        console.error('❌ Refund failed:', refundError.message);
        // 返金に失敗しても、キャンセル自体は続行
        refundResult = { error: refundError.message };
      }
    } else if (!canRefund) {
      console.log('⚠️  No refund - within 180 minutes of booking time');
    } else {
      console.log('⚠️  No refund - payment_intent_id or stripe_account_id missing');
    }

    // 4. DBステータス更新
    await pool.query(
      `UPDATE bookings
       SET status = 'cancelled',
           cancelled_at = NOW(),
           refunded_amount = ?
       WHERE id = ?`,
      [refundAmount, bookingId]
    );

    console.log('✅ Booking cancelled successfully');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    res.json({
      success: true,
      bookingId: bookingId,
      canRefund: canRefund,
      refundAmount: refundAmount,
      cancellationFee: canRefund ? 0 : booking.amount,
      refundResult: refundResult,
      message: canRefund
        ? '予約がキャンセルされ、全額返金されました。'
        : '予約がキャンセルされました。180分以内のキャンセルのため、キャンセル料が発生します。'
    });

  } catch (error) {
    console.error('❌ Cancellation error:', error.message);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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

    // If not verified, return as user but include provider_id for profile loading
    if (provider.verified === 0) {
      res.json({
        success: true,
        user: {
          email: provider.email,
          name: provider.name,
          provider_id: provider.id
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

// Provider registration (account creation)
app.post('/api/register', [
  body('username').trim().isLength({ min: 4 }).withMessage('Username must be at least 4 characters'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('phone').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { username, password, phone } = req.body;

    // Check if username already exists
    const [existing] = await pool.query(
      'SELECT id FROM providers WHERE id = ? OR email = ?',
      [username, username]
    );

    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'このユーザー名は既に使用されています'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate provider ID
    const providerId = `provider_${Date.now()}`;

    // Generate unique invite code for new user
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let inviteCode = '';
    for (let i = 0; i < 8; i++) {
      inviteCode += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    // Ensure invite code is unique
    let isUnique = false;
    while (!isUnique) {
      const [existing] = await pool.query(
        'SELECT id FROM providers WHERE invite_code = ?',
        [inviteCode]
      );
      if (existing.length === 0) {
        isUnique = true;
      } else {
        inviteCode = '';
        for (let i = 0; i < 8; i++) {
          inviteCode += chars.charAt(Math.floor(Math.random() * chars.length));
        }
      }
    }

    // Insert new provider with invite code
    await pool.query(
      `INSERT INTO providers (id, email, password, phone, verified, invite_code, created_at)
       VALUES (?, ?, ?, ?, 0, ?, NOW())`,
      [providerId, username, hashedPassword, phone || null, inviteCode]
    );

    // Generate JWT token
    const token = jwt.sign(
      {
        id: providerId,
        email: username,
        role: 'provider'
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log(`✅ New account registered: ${username} (${providerId})`);

    res.json({
      success: true,
      providerId: providerId,
      token: token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, error: 'Registration failed' });
  }
});

// Update provider profile (for profile registration after account creation)
app.post('/api/providers/:providerId/profile', authenticateToken, async (req, res) => {
  try {
    const { providerId } = req.params;

    // Check authorization
    if (req.user.id !== providerId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const {
      name,
      gender,
      birthDate,
      phone,
      email,
      postalCode,
      prefecture,
      city,
      address,
      building,
      inviteCode
    } = req.body;

    // Update provider profile
    await pool.query(
      `UPDATE providers SET
        name = ?,
        gender = ?,
        birth_date = ?,
        phone = ?,
        email = ?,
        postal_code = ?,
        prefecture = ?,
        city = ?,
        address = ?,
        building = ?,
        invite_code = ?
       WHERE id = ?`,
      [
        name,
        gender,
        birthDate,
        phone,
        email,
        postalCode,
        prefecture,
        city,
        address,
        building,
        inviteCode,
        providerId
      ]
    );

    console.log(`✅ Profile updated for provider: ${providerId}`);

    res.json({
      success: true,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ success: false, error: 'Profile update failed' });
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

    // Create a Connect Express account with monthly payout schedule (25th)
    // 毎月25日に自動振込。24日にAccount Debitsで振込手数料250円を控除
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
            interval: 'monthly',
            monthly_anchor: 25, // 毎月25日に自動振込
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
      paymentIntentId: paymentIntent.id,
      stripeAccountId: stripeAccountId,
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

// Update payout schedule for existing connected account
app.post('/api/stripe/connect/payout-schedule/:accountId', async (req, res) => {
  try {
    const { accountId } = req.params;

    // Update to monthly payout on 25th
    const account = await stripe.accounts.update(accountId, {
      settings: {
        payouts: {
          schedule: {
            interval: 'monthly',
            monthly_anchor: 25,
          },
        },
      },
    });

    res.json({
      success: true,
      accountId: account.id,
      payoutSchedule: account.settings?.payouts?.schedule,
    });
  } catch (error) {
    console.error('Error updating payout schedule:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 振込手数料控除（毎月24日に実行）
// ============================================

// 振込手数料定数
const TRANSFER_FEE = 250; // 円

// 単一のConnected Accountから振込手数料を控除
app.post('/api/stripe/deduct-transfer-fee/:accountId', async (req, res) => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('💰 Transfer Fee Deduction Request');

  try {
    const { accountId } = req.params;

    // 1. Connected Accountの残高を確認
    const balance = await stripe.balance.retrieve({
      stripeAccount: accountId,
    });
    const availableBalance = balance.available.find(b => b.currency === 'jpy')?.amount || 0;
    console.log(`📊 Account ${accountId}: Available balance = ${availableBalance} JPY`);

    // 残高が振込手数料未満の場合はスキップ
    if (availableBalance < TRANSFER_FEE) {
      console.log(`⚠️  Skipping: Balance (${availableBalance}) < Transfer fee (${TRANSFER_FEE})`);
      return res.json({
        success: false,
        accountId,
        reason: 'insufficient_balance',
        availableBalance,
        transferFee: TRANSFER_FEE,
      });
    }

    // 2. Account Debitで振込手数料を控除
    const charge = await stripe.charges.create({
      amount: TRANSFER_FEE,
      currency: 'jpy',
      source: accountId,
      description: `振込手数料 (${new Date().toISOString().slice(0, 7)})`,
    });

    console.log(`✅ Transfer fee deducted: ${charge.id}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    res.json({
      success: true,
      accountId,
      chargeId: charge.id,
      amount: TRANSFER_FEE,
      previousBalance: availableBalance,
      newBalance: availableBalance - TRANSFER_FEE,
    });

  } catch (error) {
    console.error('❌ Error deducting transfer fee:', error.message);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    res.status(500).json({ error: error.message });
  }
});

// 全Connected Accountの振込手数料を一括控除（バッチ処理）
// 毎月24日にCronで実行: curl -X POST http://localhost:3001/api/stripe/batch-deduct-transfer-fees
app.post('/api/stripe/batch-deduct-transfer-fees', async (req, res) => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('💰 Batch Transfer Fee Deduction Started');
  console.log(`📅 Date: ${new Date().toISOString()}`);

  try {
    // 1. Stripe Account IDを持つ全プロバイダーを取得
    const [providers] = await pool.query(
      'SELECT id, email, stripe_account_id FROM providers WHERE stripe_account_id IS NOT NULL'
    );

    console.log(`📊 Found ${providers.length} providers with Stripe accounts`);

    const results = {
      total: providers.length,
      success: [],
      skipped: [],
      failed: [],
    };

    // 2. 各プロバイダーに対して振込手数料を控除
    for (const provider of providers) {
      const accountId = provider.stripe_account_id;

      try {
        // 残高確認
        const balance = await stripe.balance.retrieve({
          stripeAccount: accountId,
        });
        const availableBalance = balance.available.find(b => b.currency === 'jpy')?.amount || 0;

        // 残高不足の場合はスキップ
        if (availableBalance < TRANSFER_FEE) {
          console.log(`⚠️  [${provider.id}] Skipped: Balance ${availableBalance} < ${TRANSFER_FEE}`);
          results.skipped.push({
            providerId: provider.id,
            accountId,
            reason: 'insufficient_balance',
            balance: availableBalance,
          });
          continue;
        }

        // Account Debitで控除
        const charge = await stripe.charges.create({
          amount: TRANSFER_FEE,
          currency: 'jpy',
          source: accountId,
          description: `振込手数料 (${new Date().toISOString().slice(0, 7)})`,
        });

        console.log(`✅ [${provider.id}] Deducted ${TRANSFER_FEE} JPY (${charge.id})`);
        results.success.push({
          providerId: provider.id,
          accountId,
          chargeId: charge.id,
          amount: TRANSFER_FEE,
        });

      } catch (providerError) {
        console.error(`❌ [${provider.id}] Error: ${providerError.message}`);
        results.failed.push({
          providerId: provider.id,
          accountId,
          error: providerError.message,
        });
      }
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📊 Results: ${results.success.length} success, ${results.skipped.length} skipped, ${results.failed.length} failed`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    res.json(results);

  } catch (error) {
    console.error('❌ Batch processing error:', error.message);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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

// ========================================
// Invite Code & Coupon System
// ========================================

// Generate a unique invite code
function generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars (I, O, 0, 1)
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Generate a unique coupon code
function generateCouponCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'CPN-';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Get user's invite code (generate if doesn't exist)
app.get('/api/users/:userId/invite-code', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user has invite code
    const [rows] = await pool.query(
      'SELECT invite_code FROM providers WHERE id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    let inviteCode = rows[0].invite_code;

    // Generate if doesn't exist
    if (!inviteCode) {
      inviteCode = generateInviteCode();

      // Ensure uniqueness
      let isUnique = false;
      while (!isUnique) {
        const [existing] = await pool.query(
          'SELECT id FROM providers WHERE invite_code = ?',
          [inviteCode]
        );
        if (existing.length === 0) {
          isUnique = true;
        } else {
          inviteCode = generateInviteCode();
        }
      }

      await pool.query(
        'UPDATE providers SET invite_code = ? WHERE id = ?',
        [inviteCode, userId]
      );
    }

    res.json({ success: true, inviteCode });
  } catch (error) {
    console.error('Error getting invite code:', error);
    res.status(500).json({ error: error.message });
  }
});

// Validate and apply invite code
app.post('/api/invite/apply', authenticateToken, async (req, res) => {
  try {
    const { inviteCode, inviteeId } = req.body;

    if (!inviteCode || !inviteeId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Find the inviter by invite code
    const [inviterRows] = await pool.query(
      'SELECT id, name FROM providers WHERE invite_code = ?',
      [inviteCode]
    );

    if (inviterRows.length === 0) {
      return res.status(404).json({ success: false, error: '招待コードが見つかりません' });
    }

    const inviter = inviterRows[0];

    // Cannot invite yourself
    if (inviter.id === inviteeId) {
      return res.status(400).json({ success: false, error: '自分の招待コードは使用できません' });
    }

    // Check if invitee has already used an invite code
    const [existingReferral] = await pool.query(
      'SELECT id FROM invite_referrals WHERE invitee_id = ?',
      [inviteeId]
    );

    if (existingReferral.length > 0) {
      return res.status(400).json({ success: false, error: '招待コードは既に使用済みです' });
    }

    // Create referral record
    const [referralResult] = await pool.query(
      'INSERT INTO invite_referrals (invite_code, inviter_id, invitee_id) VALUES (?, ?, ?)',
      [inviteCode, inviter.id, inviteeId]
    );

    const referralId = referralResult.insertId;

    // Create coupon for invitee (500 yen off)
    const inviteeCouponCode = generateCouponCode();
    await pool.query(
      `INSERT INTO coupons (user_id, code, discount_amount, discount_type, source, referral_id, expires_at)
       VALUES (?, ?, 500, 'fixed', 'invite_received', ?, DATE_ADD(NOW(), INTERVAL 90 DAY))`,
      [inviteeId, inviteeCouponCode, referralId]
    );

    // Create coupon for inviter (500 yen off)
    const inviterCouponCode = generateCouponCode();
    await pool.query(
      `INSERT INTO coupons (user_id, code, discount_amount, discount_type, source, referral_id, expires_at)
       VALUES (?, ?, 500, 'fixed', 'invite_given', ?, DATE_ADD(NOW(), INTERVAL 90 DAY))`,
      [inviter.id, inviterCouponCode, referralId]
    );

    console.log(`✅ Invite code applied: ${inviter.id} invited ${inviteeId}`);

    res.json({
      success: true,
      message: '招待コードが適用されました！500円オフクーポンを獲得しました。',
      couponCode: inviteeCouponCode,
      inviterName: inviter.name
    });
  } catch (error) {
    console.error('Error applying invite code:', error);
    res.status(500).json({ error: error.message });
  }
});

// Validate invite code (check if it exists, without applying)
app.get('/api/invite/validate/:code', async (req, res) => {
  try {
    const { code } = req.params;

    const [rows] = await pool.query(
      'SELECT id, name FROM providers WHERE invite_code = ?',
      [code]
    );

    if (rows.length === 0) {
      return res.json({ valid: false, error: '招待コードが見つかりません' });
    }

    res.json({
      valid: true,
      inviterName: rows[0].name
    });
  } catch (error) {
    console.error('Error validating invite code:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user's coupons
app.get('/api/users/:userId/coupons', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    const [coupons] = await pool.query(
      `SELECT id, code, discount_amount, discount_type, is_used, expires_at, source, created_at
       FROM coupons
       WHERE user_id = ? AND is_used = 0 AND (expires_at IS NULL OR expires_at > NOW())
       ORDER BY created_at DESC`,
      [userId]
    );

    res.json({ success: true, coupons });
  } catch (error) {
    console.error('Error getting coupons:', error);
    res.status(500).json({ error: error.message });
  }
});

// Use a coupon
app.post('/api/coupons/:couponId/use', authenticateToken, async (req, res) => {
  try {
    const { couponId } = req.params;
    const { userId } = req.body;

    // Get coupon
    const [coupons] = await pool.query(
      'SELECT * FROM coupons WHERE id = ? AND user_id = ?',
      [couponId, userId]
    );

    if (coupons.length === 0) {
      return res.status(404).json({ error: 'Coupon not found' });
    }

    const coupon = coupons[0];

    if (coupon.is_used) {
      return res.status(400).json({ error: 'Coupon already used' });
    }

    if (coupon.expires_at && new Date(coupon.expires_at) < new Date()) {
      return res.status(400).json({ error: 'Coupon expired' });
    }

    // Mark as used
    await pool.query(
      'UPDATE coupons SET is_used = 1, used_at = NOW() WHERE id = ?',
      [couponId]
    );

    res.json({
      success: true,
      discount: coupon.discount_amount,
      discountType: coupon.discount_type
    });
  } catch (error) {
    console.error('Error using coupon:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get referral stats for a user
app.get('/api/users/:userId/referral-stats', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Count how many people this user has invited
    const [inviteCount] = await pool.query(
      'SELECT COUNT(*) as count FROM invite_referrals WHERE inviter_id = ?',
      [userId]
    );

    // Get total coupons earned from referrals
    const [couponStats] = await pool.query(
      `SELECT COUNT(*) as total, SUM(discount_amount) as totalValue
       FROM coupons WHERE user_id = ? AND source = 'invite_given'`,
      [userId]
    );

    res.json({
      success: true,
      inviteCount: inviteCount[0].count,
      totalCouponsEarned: couponStats[0].total || 0,
      totalValueEarned: couponStats[0].totalValue || 0
    });
  } catch (error) {
    console.error('Error getting referral stats:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});
