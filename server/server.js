require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Paynow } = require('paynow');

const app = express();
app.use(cors());
app.use(express.json());

const PAYNOW_INTEGRATION_ID = process.env.PAYNOW_INTEGRATION_ID || '23962';
const PAYNOW_INTEGRATION_KEY = process.env.PAYNOW_INTEGRATION_KEY || '79947988-9f35-4e6f-8e3b-4f66f13be66c';
const PAYNOW_MERCHANT_EMAIL = process.env.PAYNOW_MERCHANT_EMAIL || 'anotidatays29@gmail.com';

const paynow = new Paynow(PAYNOW_INTEGRATION_ID, PAYNOW_INTEGRATION_KEY);

paynow.resultUrl = 'https://example.com/paynow/result';
paynow.returnUrl = 'https://example.com/paynow/return';

// POST /api/pay — initiate an EcoCash mobile payment
app.post('/api/pay', async (req, res) => {
  const { phone, amount, reference } = req.body;

  if (!phone || !amount || !reference) {
    return res.status(400).json({ success: false, error: 'Missing required fields: phone, amount, reference' });
  }

  if (typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ success: false, error: 'amount must be a positive number' });
  }

  try {
    const payment = paynow.createPayment(reference, PAYNOW_MERCHANT_EMAIL);
    payment.add(reference, amount);

    const response = await paynow.sendMobile(payment, phone, 'ecocash');

    if (response.success) {
      return res.json({ success: true, pollUrl: response.pollUrl });
    } else {
      return res.status(502).json({ success: false, error: response.error || 'Payment initiation failed' });
    }
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message || 'Internal server error' });
  }
});

// GET /api/poll?url=<pollUrl> — check transaction status
app.get('/api/poll', async (req, res) => {
  const { url } = req.query;

  if (!url) {
    return res.status(400).json({ success: false, error: 'Missing required query param: url' });
  }

  try {
    const status = await paynow.pollTransaction(url);

    return res.json({
      success: true,
      paid: status.paid(),
      status: status.status,
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message || 'Failed to poll transaction' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Paynow server running on port ${PORT}`));
