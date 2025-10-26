const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

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
      thisMonthTotal: thisMonth[0].total,
      pendingTotal: pending[0].total,
      paidTotal: paid[0].total,
      totalRevenue: pending[0].total + paid[0].total
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

    const [rows] = await pool.query(query, params);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create/Update salon
app.post('/api/salons', async (req, res) => {
  try {
    const { id, provider_id, salon_name, category, prefecture, city, address, description } = req.body;
    const [result] = await pool.query(
      'INSERT INTO salons (id, provider_id, salon_name, category, prefecture, city, address, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE salon_name=?, category=?, prefecture=?, city=?, address=?, description=?',
      [id, provider_id, salon_name, category, prefecture, city, address, description, salon_name, category, prefecture, city, address, description]
    );
    res.json({ success: true, id });
  } catch (error) {
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
    const [result] = await pool.query(
      'INSERT INTO availability_calendar (id, provider_id, date, time_slot, is_available) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE is_available=?',
      [id, provider_id, date, time_slot, is_available, is_available]
    );
    res.json({ success: true, id });
  } catch (error) {
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
    const { id, provider_id, salon_id, menu_name, description, price, duration, category } = req.body;
    const [result] = await pool.query(
      'INSERT INTO service_menus (id, provider_id, salon_id, menu_name, description, price, duration, category) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE menu_name=?, description=?, price=?, duration=?, category=?',
      [id, provider_id, salon_id, menu_name, description, price, duration, category, menu_name, description, price, duration, category]
    );
    res.json({ success: true, id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete menu
app.delete('/api/menus/:menuId', async (req, res) => {
  try {
    await pool.query('DELETE FROM service_menus WHERE id = ?', [req.params.menuId]);
    res.json({ success: true });
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

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});
