const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Initialize Stripe
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
app.use(cors());
app.use(express.json());

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
app.get('/api/bookings/:providerId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM bookings WHERE provider_id = ? ORDER BY booking_date DESC',
      [req.params.providerId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get revenue summary
app.get('/api/revenue-summary/:providerId', async (req, res) => {
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
app.get('/api/salons/:providerId', async (req, res) => {
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
    const { category, subcategory, location, search, limit } = req.query;
    console.log('🔍 /api/services called with params:', { category, subcategory, location, search, limit });

    let query = 'SELECT * FROM services WHERE is_active = 1';
    const params = [];

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }
    if (subcategory) {
      query += ' AND subcategory = ?';
      params.push(subcategory);
    }
    if (location) {
      query += ' AND location = ?';
      params.push(location);
    }
    if (search) {
      query += ' AND (title LIKE ? OR description LIKE ? OR provider_name LIKE ?)';
      const searchPattern = `%${search}%`;
      params.push(searchPattern, searchPattern, searchPattern);
    }

    query += ' ORDER BY rating DESC, reviews_count DESC';

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
app.post('/api/salons', async (req, res) => {
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
app.delete('/api/salons/:salonId', async (req, res) => {
  try {
    await pool.query('DELETE FROM salons WHERE id = ?', [req.params.salonId]);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get availability calendar
app.get('/api/availability/:providerId', async (req, res) => {
  try {
    const { date } = req.query;
    let query = 'SELECT * FROM availability_calendar WHERE provider_id = ?';
    const params = [req.params.providerId];

    if (date) {
      query += ' AND date = ?';
      params.push(date);
    }

    query += ' ORDER BY date, time_slot';
    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update availability
app.post('/api/availability', async (req, res) => {
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
app.get('/api/chats/:providerId', async (req, res) => {
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
      customer_phone, customer_email, service_name,
      booking_date, time_slot, price, status, notes
    } = req.body;

    await pool.query(
      `INSERT INTO bookings (
        id, provider_id, salon_id, service_id, customer_name,
        customer_phone, customer_email, service_name,
        booking_date, time_slot, price, status, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id, provider_id, salon_id, service_id, customer_name,
        customer_phone, customer_email, service_name,
        booking_date, time_slot, price, status, notes
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
app.get('/api/menus/:salonId', async (req, res) => {
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
app.post('/api/menus', async (req, res) => {
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
app.delete('/api/menus/:menuId', async (req, res) => {
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
app.get('/api/providers/:providerId', async (req, res) => {
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
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const [rows] = await pool.query(
      'SELECT * FROM providers WHERE email = ? AND password = ?',
      [email, password]
    );
    if (rows.length > 0) {
      res.json({ success: true, provider: rows[0] });
    } else {
      res.status(401).json({ success: false, error: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
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
app.patch('/api/providers/:providerId', async (req, res) => {
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

// Change provider password
app.patch('/api/providers/:providerId/password', async (req, res) => {
  try {
    console.log('PATCH /api/providers/:providerId/password - Request body:', req.body);
    console.log('Provider ID:', req.params.providerId);
    const { current_password, new_password } = req.body;

    // Verify current password
    const [rows] = await pool.query(
      'SELECT * FROM providers WHERE id = ? AND password = ?',
      [req.params.providerId, current_password]
    );

    if (rows.length === 0) {
      console.log('PATCH /api/providers/:providerId/password - Current password incorrect');
      res.status(401).json({ success: false, error: 'Current password is incorrect' });
      return;
    }

    // Update password
    await pool.query(
      'UPDATE providers SET password = ? WHERE id = ?',
      [new_password, req.params.providerId]
    );

    console.log('PATCH /api/providers/:providerId/password - Success');
    res.json({ success: true });
  } catch (error) {
    console.error('PATCH /api/providers/:providerId/password - Error:', error.message);
    res.status(500).json({ error: error.message });
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
app.post('/api/stripe/connect/account', async (req, res) => {
  try {
    const { email, providerId } = req.body;

    // Create a Connect Express account
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
            monthly_anchor: 25, // Payout on the 25th of each month
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
app.post('/api/stripe/connect/account-link', async (req, res) => {
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
app.get('/api/stripe/connect/account/:accountId', async (req, res) => {
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
